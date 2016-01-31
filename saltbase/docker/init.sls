{%- set environment_file = '/etc/default/docker' %}
{%- set docker_ver = pillar['docker_ver'] %}
include:
  - gcloud
  - collectd

{{ environment_file }}:
  file.managed:
    - source: salt://docker/files/docker-defaults
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

dockerrepo:
  pkgrepo.managed:
    - humanname: apt.dockerproject.org
    - name: deb https://apt.dockerproject.org/repo ubuntu-trusty main
    - file: /etc/apt/sources.list.d/dockerengine.list
    - keyid: 58118E89F3A912897C070ADBF76221572C52609D
    - keyserver: hkp://p80.pool.sks-keyservers.net:80
    - require_in:
      - pkg: docker-package

docker-package:
  pkg.installed:
    - name: docker-engine
    - version: {{ docker_ver }}~trusty

docker:
  service.running:
    - enable: True
    - require:
      - pkg: docker-package
    - watch:
      - file: {{ environment_file }}
      - pkg: docker-package

docker-gcr-login-script:
  file.managed:
    - name: /opt/gcloud/docker-gcr-login.sh
    - source: salt://docker/files/docker-gcr-login.sh
    - user: root
    - group: root
    - mode: 755

docker-gcr-login:
  cmd.run:
    - name: /opt/gcloud/docker-gcr-login.sh

python-pip:
  pkg.installed:
    - name: python-pip

pip-update-docker:
  cmd.run:
    - unless: 'pip show pip | grep 7.1.2'
    - name: easy_install -U pip

docker-py:
  pip.installed:
    - name: docker-py >= 1.4.0

python-dateutil:
  pip.installed:
    - name: python-dateutil == 2.4.2

/usr/share/collectd/collectd-docker.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - source: salt://docker/files/collectd-docker.sh
    - require:
      - pkg: collectdpackage

extend:
  collectd:
    service.running:
      - watch:
        - file: /usr/share/collectd/collectd-docker.sh
