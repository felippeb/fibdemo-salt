include:
  - logging

pkg-core-logstash:
  pkg.installed:
    - pkgs:
      - openjdk-7-jre-headless

logstash:
  pkgrepo.managed:
    - humanname: logstash official repo
    - name: deb http://packages.elasticsearch.org/logstash/1.5/debian stable main
    - key_url: https://packages.elasticsearch.org/GPG-KEY-elasticsearch
    - require_in:
      - pkg: logstash
    - require:
      - pkg: pkg-core-logstash
  pkg.installed:
    - refresh: True

/etc/logstash/conf.d/collectd.conf:
  file.managed:
    - source: salt://elasticsearch/files/logstash/collectd.conf
    - user: root
    - group: root
    - mode: 0644
    - require:
      - pkg: logstash

logstash-service:
  service.running:
    - name: logstash
    - enable: True
    - require:
      - pkg: logstash
    - watch:
      - pkg: logstash
      - file: /etc/logstash/conf.d/collectd.conf
