base:
  '*':
    - base
    - debian-auto-upgrades
    - users
    - saltminion
    - collectd

  'roles:fibdemo':
    - match: grain
    - docker
    - gcloud
    - fibdemo

  'roles:jenkins':
    - match: grain
    - docker
    - gcloud

  'roles:elasticsearch':
    - match: grain
    - elasticsearch

  'roles:saltmaster':
    - match: grain
    - saltmaster
