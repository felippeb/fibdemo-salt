# fibdemo-salt

This repo contains the saltbase and pillarbase configs, as well as the salt-cloud automation scripts which stand up the project.

#/saltbase

Salt states.

#/pillarbase

Salt pillar data.

#/envstandup

This directory hoses the env standup scripts. There are three main scripts:

env-standup.sh: this script is the master control script. it will go from start to finish.
do-network.sh: this script does network tasks for env-standup.sh
do-remote-standup.sh: this script stands up the saltmaster, preps this saltmaster for salt-cloud, then installs the rest of the vms from this salt master. 

#/envstandup/salt

This folder contains the salt-cloud configs that accompany env-standup.sh. You will need to copy these scripts into your local /etc/salt/ directory.

#/envstandup/network

These are yaml files which accompany do-network.sh. These yaml files document the firewall rules, forwarding rules, addresses, etc.
