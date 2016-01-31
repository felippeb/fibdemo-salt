#!/bin/bash

echo "logging docker into b.gcr.io repo"
if docker login -e 1041904472770-compute@developer.gserviceaccount.com -u _json_key -p "$(cat /opt/gcloud/fibdemo-a96cb930a7c2.json)" https://b.gcr.io; then
  echo "successfully logged docker into b.gcr.io repo"
else
  echo "login to b.gcr.io repo has failed"
fi
