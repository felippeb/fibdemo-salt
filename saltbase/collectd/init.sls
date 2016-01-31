{%- set collectd_package_ver = pillar['collectd_package_ver'] %}

collectd-5-5.ppa:
  pkgrepo.absent:
    - ppa: rullmann/collectd 

collectd-5.5-official-repo:
  pkgrepo.absent:
    - humanname: collectd official repo
    - name: deb [arch=amd64] http://pkg.ci.collectd.org/deb trusty collectd-5.5
    - key_url: http://pkg.ci.collectd.org/pubkey.asc

collectd.conf:
  file.managed:
    - name: /etc/collectd/collectd.conf
    - makedirs: True
    - source: salt://collectd/files/collectd.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644

collectd.conf.d:
  file.recurse:
    - name: /etc/collectd/collectd.conf.d/
    - makedirs: True
    - source: salt://collectd/files/collectd.conf.d/
    - template: jinja
    - user: root
    - group: root
    - mode: 644

collectdpackage:
  pkg.installed:
    - sources:
      - collectd: salt://collectd/files/collectd_5.5.0.178.geab8493-1~trusty_amd64.deb
    - require:
      - file: collectdconf

collectd-core-package:
  pkg.installed:
    - sources:
      - collectd-core: salt://collectd/files/collectd-core_5.5.0.178.geab8493-1~trusty_amd64.deb
    - require:
      - file: collectdconf

/usr/share/collectd/sockstat.py:
  file.managed:
    - source: salt://collectd/files/sockstat.py
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: collectdpackage

collectdservice:
  service.running:
    - name: collectd
    - restart: True
    - require:
      - pkg: collectdpackage
    - watch:
      - pkg: collectdpackage
      - file: collectd.conf 
      - file: collectd.conf.d 
      - file: /usr/share/collectd/sockstat.py
