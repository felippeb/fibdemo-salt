base:
  '*':
    - mine
    - ntp
    - users
    - collectd
    - docker
    - logging

  'roles:fibdemo':
    - match: grain
    - fibdemo

  'roles:elasticsearch':
    - match: grain
    - elasticsearch
