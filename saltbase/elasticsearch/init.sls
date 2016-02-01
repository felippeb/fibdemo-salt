include:
  - logging
  - collectd

javaoraclejre:
  pkg.installed:
    - sources:
      - oracle-java8-jre: salt://elasticsearch/files/oracle-java8-jre_8u51_amd64.deb

jre-8-oracle-x64-alternatives:
  alternatives.set:
    - name: java
    - path: /usr/lib/jvm/jre-8-oracle-x64/bin/java
    - require:
      - pkg: javaoraclejre

elasticsearch:
  pkgrepo.managed:
    - humanname: elasticsearch official repo 
    - name: deb http://packages.elastic.co/elasticsearch/1.7/debian stable main 
    - key_url: https://packages.elastic.co/GPG-KEY-elasticsearch 
    - require_in:
      - pkg: elasticsearch
  pkg.installed:
    - refresh: True
  service.running:
    - enable: True
    - require:
      - pkg: elasticsearch
    - watch:
      - pkg: elasticsearch
      - file: /etc/elasticsearch/elasticsearch.yml
      - file: /etc/default/elasticsearch

/etc/elasticsearch/elasticsearch.yml:
  file.managed:
    - source: salt://elasticsearch/files/elasticsearch-yml
    - template: jinja
    - user: root
    - group: root
    - mode: 644

/etc/default/elasticsearch:
  file.managed:
    - source: salt://elasticsearch/files/default
    - template: jinja
    - user: root
    - group: root
    - mode: 644

{% if '01' in grains['id'] %}
/etc/collectd/collectd.conf.d/elasticearch-node.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - source: salt://elasticsearch/files/collectd-elasticsearch-node
    - require:
      - pkg: collectdpackage
{% else %}
/etc/collectd/collectd.conf.d/elasticearch-cluster.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - source: salt://elasticsearch/files/collectd-elasticsearch-cluster
    - require:
      - pkg: collectdpackage
{% endif %}

python-elasticsearch-curator:
  pkgrepo.managed:
    - humanname: curator official repo
    - name: deb http://packages.elasticsearch.org/curator/3/debian stable main
    - require_in:
      - pkg: python-elasticsearch-curator
  pkg.installed:
    - refresh: True

curator-cron:
  file.managed:
    - source: salt://elasticsearch/files/curator-cron
    - name: /etc/cron.d/curator
    - user: root
    - group: root
    - mode: 644

curator-logrotote:
  file.managed:
    - source: salt://elasticsearch/files/curator-logrotote
    - name: /etc/logrotate.d/curator
    - user: root
    - group: root
    - mode: 644

curator-rsyslog:
  file.managed:
    - source: salt://elasticsearch/files/40-curator.conf
    - name: /etc/rsyslog.d/40-curator.conf
    - user: root
    - group: root
    - mode: 644

extend:
  rsyslog:
    service.running:
      - watch:
        - file: curator-rsyslog
  collectd:
    service.running:
      - watch:
        - file: /etc/collectd/collectd.conf.d/elasticearch-node.conf
        - file: /etc/collectd/collectd.conf.d/elasticearch-cluster.conf
