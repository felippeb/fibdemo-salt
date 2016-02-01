{%- set kibana4version = pillar['kibana4version'] %}
include:
  - nginx

kibana-nginx-conf:
  file.managed:
    - name: /etc/nginx/sites-available/elasticsearch.conf
    - source: salt://elasticsearch/files/elasticsearch-nginx-conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx

kibana-nginx-conf-enabled:
  file.symlink:
    - name: /etc/nginx/sites-enabled/elasticsearch.conf
    - target: /etc/nginx/sites-available/elasticsearch.conf
    - user: root
    - group: root 
    - require:
      - file: kibana-nginx-conf

/etc/nginx/certs:
  file.directory: []

/etc/nginx/certs/kibana.key:
  x509.private_key_managed:
    - bits: 4096
    - backup: True
    - require:
      - file: /etc/nginx/certs

/etc/nginx/certs/kibana.crt:
  x509.certificate_managed:
    - signing_private_key: /etc/nginx/certs/kibana.key
    - CN: kibana.fibdemo.com
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
      - x509: /etc/nginx/certs/kibana.key

kibanahtpasswd:
  file.managed:
    - name: /etc/nginx/htpasswd.users
    - source: salt://elasticsearch/files/htpasswd
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx

kibana4-install:
  archive.extracted:
    - name: /opt/
    - source: salt://elasticsearch/files/{{ kibana4version }}.tar.gz 
    - source_hash: {{ pillar['kibana4hash'] }}
    - archive_format: tar
    - tar_options: zv
    - archive_user: root
    - if_missing: /opt/{{ kibana4version }}

kibana4-symlink:
  file.symlink:
    - name: /opt/kibana
    - target: /opt/{{ kibana4version }}
    - user: root
    - group: root
    - require:
      - archive: kibana4-install

kibana4:
  file.managed:
    - source: salt://elasticsearch/files/kibana4-init
    - name: /etc/init.d/kibana4
    - user: root
    - group: root
    - mode: 755
  service.running:
    - enable: True
    - require:
      - file: kibana4
    - watch: 
      - file: kibana4

extend:
  nginx:
    service.running:
      - watch:
        - file: /etc/nginx/sites-available/elasticsearch.conf
