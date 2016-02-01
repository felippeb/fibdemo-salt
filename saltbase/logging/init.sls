rsyslog-official-repo:
  pkgrepo.managed:
    - ppa: adiscon/v8-stable 

rsyslog-extra-pkgs:
  pkg.installed:
    - pkgs:
      - rsyslog-relp
      - rsyslog-elasticsearch
      - rsyslog-mmjsonparse
    - refresh: True
    - require:
      - pkgrepo: rsyslog-official-repo

/etc/rsyslog.conf:
  file.managed:
    - source: salt://logging/files/rsyslog-conf
    - user: root
    - group: root
    - mode: 644

/etc/rsyslog.d/21-udp.conf:
  file.absent

/etc/rsyslog.d/10-remote.conf:
  file.managed:
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - source: salt://logging/files/10-remote.conf
    - require:
      - pkgrepo: rsyslog-official-repo

/tmp/rsyslog-remote:
  file.directory:
    - user: root
    - group: root

/etc/rsyslog.d/50-default.conf:
  file.managed:
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - source: salt://logging/files/50-default-conf
    - require:
      - pkgrepo: rsyslog-official-repo

rsyslog:
  service.running:
    - restart: True
    - watch:
      - pkg: rsyslog-extra-pkgs 
      - file: /etc/rsyslog.d/50-default.conf
      - file: /etc/rsyslog.conf
      - file: /etc/rsyslog.d/10-remote.conf
