include:
  - nginx
  - git
  - docker

pkg-core-jenkins:
  pkg.installed:
    - pkgs:
      - openjdk-7-jre-headless
      - unzip
      - ruby1.9.1-full
      - zip

jenkins_group:
  group.present:
    - name: jenkins

jenkins_user:
  file.directory:
    - name: /var/lib/jenkins
    - user: jenkins
    - group: jenkins
    - mode: 0755
    - require:
      - user: jenkins_user
      - group: jenkins_group
  user.present:
    - name: jenkins
    - home: /var/lib/jenkins
    - shell: /bin/bash
    - groups:
      - jenkins
      - docker
    - require:
      - group: jenkins_group
      - pkg: docker-package

jenkins-default:
  file.managed:
    - name: /etc/default/jenkins
    - mode: 644
    - user: jenkins
    - group: jenkins
    - source: salt://jenkins/files/jenkins-default

jenkins-ssh-config:
  file.managed:
    - name: /var/lib/jenkins/.ssh/config
    - makedirs: True
    - mode: 600
    - user: jenkins
    - group: jenkins
    - source: salt://jenkins/files/ssh-config

/var/lib/jenkins/.ssh/id_rsa:
  file.managed:
    - source: salt://jenkins/files/id_rsa
    - user: jenkins
    - group: jenkins
    - mode: 400
    - makedirs: true

/var/lib/jenkins/.ssh/id_rsa.pub:
  file.managed:
    - source: salt://jenkins/files/id_rsa.pub
    - user: jenkins
    - group: jenkins
    - mode: 400
    - makedirs: true

jenkins-repo:
  pkgrepo.managed:
    - humanname: Jenkins upstream package repository
    - name: deb http://pkg.jenkins-ci.org/debian binary/
    - key_url: http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key
    - require_in:
      - pkg: jenkins

jenkins:
  pkg.installed

jenkins-service:
  service.running:
    - name: jenkins
    - enable: True
    - watch:
      - file: jenkins-default
      - pkg: jenkins

jenkinsusersudo:
  file.append:
    - name: /etc/sudoers
    - source: salt://jenkins/files/jenkins-sudo

/etc/nginx/certs:
  file.directory: []

/etc/nginx/certs/jenkins.key:
  x509.private_key_managed:
    - bits: 4096
    - backup: True
    - require:
      - file: /etc/nginx/certs

/etc/nginx/certs/jenkins.crt:
  x509.certificate_managed:
    - signing_private_key: /etc/nginx/certs/jenkins.key
    - CN: jenkins.fibdemo.com
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
      - x509: /etc/nginx/certs/jenkins.key

/etc/nginx/sites-available/jenkins.conf:
  file:
    - managed
    - source: salt://jenkins/files/jenkins.conf
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 440
    - require:
      - x509: /etc/nginx/certs/jenkins.crt
      - pkg: jenkins

/etc/nginx/sites-enabled/jenkins.conf:
  file.symlink:
    - target: /etc/nginx/sites-available/jenkins.conf
    - user: www-data
    - group: www-data

pip-nose-jenkins:
  pip.installed:
    - name: nose

extend:
  nginx:
    service.running:
      - watch:
        - file: /etc/nginx/sites-available/jenkins.conf
