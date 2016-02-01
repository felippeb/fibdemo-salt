#!/bin/bash

echo "logging docker into b.gcr.io repo"
if docker login -e fibdemodockerrepo@fibdemo-1205.iam.gserviceaccount.com -u _json_key -p "$(cat /opt/gcloud/fibdemo-auth.json)" https://b.gcr.io; then
  echo "successfully logged docker into b.gcr.io repo"
else
  echo "login to b.gcr.io repo has failed"
fi
