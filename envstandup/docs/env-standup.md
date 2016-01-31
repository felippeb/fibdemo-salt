```
Usage :  env-standup.sh [options] <install-type> <project> <region>

Installation types:
  - decrypt_keys
  - full
  - firewall-rules
  - target-pools
  - forwarding-rules
  - saltmasterstandup
  - nodestandup

Examples:
  - env-standup.sh
  - env-standup.sh full fibdemo us-central1
  - env-standup.sh -n int1 firewall-rules fibdemo us-central1
  - env-standup.sh -n infra1 -n int1 target-pools fibdemo us-east1
  - env-standup.sh -n all -l /tmp/fibdemo-standup.log firewall-rules fibdemo us-central1

Options:
-h  Display this message
-v  Display script version
-D  Show debug output.
-n  GCE Network Name. If unset, will default to a set of predetermined networks based on project.
-l  Log File Name
```
