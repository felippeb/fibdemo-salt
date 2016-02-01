base:
  '*':
    - mine
    - ntp
    - users
    - collectd
    - docker

  'roles:fibdemo':
    - match: grain
    - fibdemo
