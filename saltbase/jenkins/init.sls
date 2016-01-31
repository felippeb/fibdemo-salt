include:
  - nginx
  - git

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
    - require:
      - group: jenkins_group

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

/etc/nginx/sites-available/jenkins.conf:
  file:
    - managed
    - source: salt://jenkins/files/jenkins.conf
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 440
    - require:
      - pkg: jenkins

/etc/nginx/sites-enabled/jenkins.conf:
  file.symlink:
    - target: /etc/nginx/sites-available/jenkins.conf
    - user: www-data
    - group: www-data

extend:
  nginx:
    service.running:
      - watch:
        - file: /etc/nginx/sites-available/jenkins.conf
