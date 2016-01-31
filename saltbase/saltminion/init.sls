saltstack-ubuntu-repo:
  pkgrepo.managed:
    - humanname: repo.saltstack.com ubuntu
    - name: deb http://repo.saltstack.com/apt/ubuntu/14.04/amd64/latest trusty main
    - key_url: https://repo.saltstack.com/apt/ubuntu/14.04/amd64/latest/SALTSTACK-GPG-KEY.pub
  pkg.installed:
    - name: salt-minion
    - version: 2015.8.3+ds-1

/etc/salt/minion:
  file.managed:
    - source: salt://saltminion/files/minion
    - user: root
    - group: root
    - mode: 644

/etc/salt/minion.d/minion.conf:
  file.managed:
    - source: salt://saltminion/files/minion.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644

/etc/salt/minion.d/docker.conf:
  file.managed:
    - source: salt://saltminion/files/docker.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: true

saltminion-python-deps:
  pkg.installed:
    - pkgs:
      - libssl-dev
      - libffi-dev
      - python-setuptools
      - python-dev

pip-installed-saltminion:
  pkg.installed:
    - name: python-pip

pip-elasticsearch-2-saltminion:
  pip.removed:
    - name: elasticsearch >=2.1.0

pip-elasticsearch-saltminion:
  pip.installed:
    - name: elasticsearch >=1.0.0,<2.0.0

pip-jsonpickle-saltminion:
  pip.installed:
    - name: jsonpickle

pip-pyopenssl-saltminion:
  pip.installed:
    - name: pyopenssl >=0.15

pip-timelib-saltminion:
  pip.installed:
    - name: timelib

pip-boto-saltminion:
  pip.installed:
    - name: boto >=2.35.0
