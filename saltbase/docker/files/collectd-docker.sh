#!/bin/bash

#
# CollectD - Docker
#
# This script will collect cpu/memory stats on running docker containers using cgroup
# and output the data in a collectd-exec plugin friendly format.
#
# Author: Mike Moulton (mike@meltmedia.com)
# License: MIT
# Lightly modified by Felippe Burk (felippeburk@gmail.com)

# Location of the cgroup mount point, adjust for your system
CGROUP_MOUNT="/sys/fs/cgroup"

HOSTNAME="${COLLECTD_HOSTNAME:-localhost}"
INTERVAL="${COLLECTD_INTERVAL:-60}"

collect ()
{
  cd "$1"

  # If the directory length is 64, it's likely a docker instance
  LENGTH=$(expr length $1);
  if [ "$LENGTH" -eq "64" ]; then

    # Shorten the name to 12 for brevity, like docker does
    #NAME=$(expr substr $1 1 12);
#    NAME=$(docker inspect --format "{{ .Name }}" $1 | cut -c 2-);


#custom hacky. this skips over the folder if its not currently running in docker ps output. also skips over if container has "POD" in the name, which indicates a kubernetes pause container

if
{
docker inspect --format "{{ .Name }}" $1
} &> /dev/null; then
      CONTAINERNAME=$(docker inspect --format "{{ .Name }}" $1 | cut -c 2-);
      if [[ "${CONTAINERNAME}" =~ .*POD.* ]]; then
#        echo "container has POD in label"
        continue 1
      else
        if [[ "${CONTAINERNAME}" =~ .*controller-[a-z]* ]]; then
          NAME=$(echo $CONTAINERNAME | egrep -o controller*\(-[a-z]*\)?+)
        else
          NAME=$(echo $CONTAINERNAME)
        fi
      fi
    else
#      echo "CONTAINER IS NOT RUNNING"
      continue 1
    fi


    # If we are in a cpuacct cgroup, we can collect cpu usage stats
    if [ -e cpuacct.stat ]; then
        USER=$(cat cpuacct.stat | grep '^user' | awk '{ print $2; }');
        SYSTEM=$(cat cpuacct.stat | grep '^system' | awk '{ print $2; }');
        echo "PUTVAL \"$HOSTNAME/docker-$NAME/cpu-user\" interval=$INTERVAL N:$USER"
        echo "PUTVAL \"$HOSTNAME/docker-$NAME/cpu-system\" interval=$INTERVAL N:$SYSTEM"
    fi;

    # If we are in a memory cgroup, we can collect memory usage stats
    if [ -e memory.stat ]; then
        CACHE=$(cat memory.stat | grep '^cache' | awk '{ print $2; }');
        RSS=$(cat memory.stat | grep '^rss\ ' | awk '{ print $2; }');
        echo "PUTVAL \"$HOSTNAME/docker-$NAME/memory-cached\" interval=$INTERVAL N:$CACHE"
        echo "PUTVAL \"$HOSTNAME/docker-$NAME/memory-used\" interval=$INTERVAL N:$RSS"
    fi;

  fi;


  # Iterate over all sub directories
  for d in *
  do
    if [ -d "$d" ]; then
      ( collect "$d" )
    fi;
  done
}

while sleep "$INTERVAL"; do
  # Collect stats on memory usage
  ( collect "$CGROUP_MOUNT/memory/docker" )

  # Collect stats on cpu usage
  ( collect "$CGROUP_MOUNT/cpuacct/docker" )
done
