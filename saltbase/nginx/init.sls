nginx-stable-ppa:
  pkgrepo.absent:
    - ppa: nginx/stable 

nginx-development-ppa:
  pkgrepo.managed:
    - ppa: nginx/development

nginx:
  pkg:
    - installed 

/etc/nginx/sites-enabled/default:
  file.absent

/etc/nginx/nginx.conf:
  file:
    - managed
    - source: salt://nginx/nginx.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx

nginx-service:
  service.running:
    - enable: True
    - reload: True
    - name: nginx
    - watch:
      - pkg: nginx
      - file: /etc/nginx/nginx.conf
