{% set fibdemo_ver = pillar['fibdemo_ver'] %}
include:
  - docker
  - gcloud
  - nginx

python-m2crypto:
  pkg.installed

docker_fibdemo_{{ pillar['old_fibdemo_ver'] }}:
  docker.absent:
    - order: 1

docker_fibdemo_image:
  cmd.run:
    - unless: docker images | grep {{ pillar['docker_repo'] }}/fibdemo
    - name: gcloud docker pull {{ pillar['docker_repo'] }}/fibdemo:{{ fibdemo_ver }}
    - shell: /bin/bash
    - user: root
    - group: root
    - cwd: /root
    - require:
      - pkg: docker-engine
      - pkg: google-cloud-sdk

docker_fibdemo_container:
  docker.installed:
    - name: docker_fibdemo_{{ fibdemo_ver }}
    - image: {{ pillar['docker_repo'] }}/fibdemo:{{ fibdemo_ver }}
    - ports:
      - 5000: 5000
    - require:
      - cmd: docker_fibdemo_image
      - pkg: docker-package
    - order: 120

docker_fibdemo_running:
  docker.running:
    - container: docker_fibdemo_{{ fibdemo_ver }}
    - image: {{ pillar['docker_repo'] }}/fibdemo:{{ fibdemo_ver }}
    - ports:
      - 5000: 5000
    - volumes:
        "/var/log/fibdemo/":
          bind: "/var/fibdemo/logs/"
          ro: false
    - require:
      - docker: docker_fibdemo_container
      - pkg: docker-package
    - order: 121

/etc/nginx/certs:
  file.directory: []

/etc/nginx/certs/fibdemo.key:
  x509.private_key_managed:
    - bits: 4096
    - backup: True
    - require:
      - file: /etc/nginx/certs

/etc/nginx/certs/fibdemo.crt:
  x509.certificate_managed:
    - signing_private_key: /etc/nginx/certs/fibdemo.key
    - CN: fibdemo.fibdemo.com
    - C: US
    - ST: Utah
    - L: Salt Lake City
    - basicConstraints: "critical CA:true"
    - keyUsage: "critical cRLSign, keyCertSign"
    - subjectKeyIdentifier: hash
    - authorityKeyIdentifier: keyid,issuer:always
    - days_valid: 365
    - days_remaining: 0
    - backup: True
    - require:
      - x509: /etc/nginx/certs/fibdemo.key

/etc/nginx/sites-available/fibdemo.conf:
  file:
    - managed
    - source: salt://fibdemo/files/fibdemo.conf
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 440
    - require:
      - x509: /etc/nginx/certs/fibdemo.crt
      - pkg: fibdemo

/etc/nginx/sites-enabled/fibdemo.conf:
  file.symlink:
    - target: /etc/nginx/sites-available/fibdemo.conf
    - user: www-data
    - group: www-data

extend:
  nginx:
    service.running:
      - watch:
        - file: /etc/nginx/sites-available/fibdemo.conf
