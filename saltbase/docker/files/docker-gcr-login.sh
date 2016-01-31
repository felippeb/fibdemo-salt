#!/bin/bash

echo "logging docker into b.gcr.io repo"
if docker login -e 974230463687-g61h8t8a96q1qgnm4kpauin3b5r9lhto@developer.gserviceaccount.com -u _json_key -p "$(cat /opt/gcloud/DPC-BAK-001-b89a990bae08.json)" https://b.gcr.io; then
  echo "successfully logged docker into b.gcr.io repo"
else
  echo "login to b.gcr.io repo has failed"
fi
