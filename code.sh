#!/usr/bin/bash -e

nodes_path=/sys/devices/system/node/
if [ ! -d $nodes_path ]; then
  echo "ERROR: $nodes_path does not exist"
  exit 1
fi

reserve_pages()
{
  echo $1 > $nodes_path/$2/hugepages/hugepages-${3}/nr_hugepages
}

get_pagesz_nrpages(){
  page_size=${1}
  shift
  for x in ${@}; do
    node=${x%%:*}
    val=${x##*:}
    if [ ! -d "$nodes_path/node${node}" ]; then
      echo "ERROR: NUMA node ${node} not found"
    else
      echo Setting NUMA node $node Hugepagesize ${page_size} nr_hugepages to $val
      reserve_pages $val node$node ${page_size}
    fi
  done
}
# kernel commandline contains:  abc_hugepages_numa=a:n,b:n,...
# where a is node number,  and b is the number of hugepages
cmdline="$(cat /proc/cmdline)"
VALS=$(echo $cmdline |grep -oe '\s*abc_hugepages_numa=\S*' |cut -f2 -d= |tr , ' ')
get_pagesz_nrpages '1048576kB' ${VALS}
VALS_2MB=$(echo $cmdline |grep -oe '\s*abc_2mb_hugepages_numa=\S*' |cut -f2 -d= |tr , ' ')
if [[ ${VALS_2MB} =~ ^[0-9]+$ ]]
then
  sysctl -w vm.nr_hugepages=${VALS_2MB}
else
  get_pagesz_nrpages '2048kB' ${VALS_2MB}
fi
