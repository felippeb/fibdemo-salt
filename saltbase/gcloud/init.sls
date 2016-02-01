google-cloud-sdk-repo:
  pkgrepo.managed:
    - humanname: Google Cloud
    - name: deb http://packages.cloud.google.com/apt cloud-sdk-trusty main
    - key_url: https://packages.cloud.google.com/apt/doc/apt-key.gpg
    - require_in:
      - pkg: google-cloud-sdk

google-cloud-sdk:
  pkg.latest

/opt/gcloud/gcloudinstall.sh:
  file.managed:
    - source: salt://gcloud/files/gcloudinstall.sh
    - template: jinja
{%- if 'jenkins' in grains['id'] %}
    - user: jenkins
    - group: jenkins
{%- else %}
    - user: root
    - group: root
{%- endif %}
    - mode: 755
    - makedirs: true

/opt/gcloud/fibdemo-auth.json:
  file.managed:
    - source: salt://gcloud/files/fibdemo-auth.json
{%- if 'jenkins' in grains['id'] %}
    - user: jenkins
    - group: jenkins
{%- else %}
    - user: root
    - group: root
{%- endif %}
    - mode: 400
    - makedirs: true

install-gcloud:
  cmd.run:
    - name: /opt/gcloud/gcloudinstall.sh
{%- if 'jenkins' in grains['id'] %}
    - unless: test -f /var/lib/jenkins/.config/gcloud/gce
    - user: jenkins
    - group: jenkins
{%- else %}
    - unless: test -f /root/.config/gcloud/gce
    - user: root
    - group: root
{%- endif %}
    - require:
      - file: /opt/gcloud/gcloudinstall.sh
      - file: /opt/gcloud/fibdemo-auth.json
