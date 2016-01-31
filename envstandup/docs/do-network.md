```
Usage :  do-remote-standup.sh [options] <install-type> <network> <project> <region>

Install Types:
  - delete_defaultnetwork
  - create_fwrule
  - delete_fwrule
  - create_address
  - delete_address
  - create_network
  - delete_network
  - create_route
  - delete_route
  - create_targetpool
  - delete_targetpool
  - create_forwardingrule
  - delete_forwardingrule

Regions:
  - us-central1
  - us-east1
  - asia-east1
  - europe-west1

Examples:
  - do-remote-standup.sh
  - do-remote-standup.sh create_fwrule infra1 fibdemo us-central1
  - do-remote-standup.sh -D create_route int1 fibdemo us-east1

Options:
-h  Display this message
-v  Display script version
-D  Show debug output.
-l  Log File Name
```
