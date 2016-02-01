pkg-core:
  pkg.installed:
    - names:
      - curl
      - apt-transport-https
      - python-apt
      - python-software-properties
      - sysstat
      - python-m2crypto

set-utc-timezone:
  timezone.system:
    - name: 'UTC'
    - utc: True
