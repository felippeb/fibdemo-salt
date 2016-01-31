
  Usage :  do-remote-standup.sh [options] <network> <project> <region>

  Regions:
    - us-central1
    - us-east1
    - asia-east1
    - europe-west1

  Examples:
    - do-remote-standup.sh
    - do-remote-standup.sh infra1 fibdemo us-central1
    - do-remote-standup.sh -m vds int1 fibdemo us-east1
    - do-remote-standup.sh -D -l /var/log/fibdemo.log log1 fibdemo us-central1

  Options:
  -h  Display this message
  -v  Display script version
  -D  Show debug output.
  -m  Map name.
  -l  Log File Name

