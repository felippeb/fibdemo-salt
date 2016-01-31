pkg-core:
  pkg.installed:
    - names:
      - curl
      - apt-transport-https
      - python-apt
      - python-software-properties
      - sysstat

set-utc-timezone:
  timezone.system:
    - name: 'UTC'
    - utc: True
