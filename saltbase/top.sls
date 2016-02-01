base:
  '*':
    - base
    - debian-auto-upgrades
    - users
    - saltminion
    - collectd
    - logging

  'roles:fibdemo':
    - match: grain
    - docker
    - gcloud
    - fibdemo

  'roles:jenkins':
    - match: grain
    - docker
    - gcloud
    - jenkins

  'roles:elasticsearch':
    - match: grain
    - elasticsearch
    - elasticsearch.kibana4
    - elasticsearch.logstash

  'roles:saltmaster':
    - match: grain
    - saltmaster
