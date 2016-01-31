{% for saltpkg in 'salt-master', 'salt-api', 'salt-cloud' %}
{{ saltpkg }}-pkg:
  pkg.installed:
    - name: {{ saltpkg }}
    - version: 2015.8.3+ds-1 
{% endfor %}

/etc/salt/master:
  file.managed:
    - source: salt://saltmaster/files/master
    - template: jinja
    - user: root
    - group: root
    - mode: 644

/etc/salt/master.d:
  file.recurse:
    - source: salt://saltmaster/files/master.d
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - clean: False

elasticsearch_returner.py:
  file.managed:
    - template: jinja
    - name: /usr/lib/python2.7/dist-packages/salt/returners/elasticsearch_return.py
    - source: salt://saltmaster/files/elasticsearch_return.py
    - user: root
    - group: root
    - mode: 644

{% for service in 'salt-master', 'salt-api' %}
{{ service }}:
  service.running:
    - enable: True 
    - watch:
      - file: /etc/salt/master
      - file: /etc/salt/master.d
    - require:
      - pkg: salt-master-pkg
{% endfor %}
