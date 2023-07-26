{%- set user = salt['pillar.get']('sift_user', 'sansforensics') -%}
{%- set all_users = salt['user.list_users']() -%}
{%- if user == "root" -%}
  {%- set home = "/root" -%}
{%- else -%}
  {%- set home = "/home/" + user -%}
{%- endif -%}

{% set tools = ['AmcacheParser','AppCompatCacheParser','bstrings','EvtxECmd','iisGeolocate','JLECmd','LECmd','MFTECmd','RBCmd','RecentFileCacheParser','RECmd','rla','SBECmd','SQLECmd','SrumECmd','WxTCmd'] %}

include:
  - sift.packages.dotnet
  - sift.config.user.user

download-all-6.zip:
  file.managed:
    - name: /tmp/All_6.zip
    - source: https://f001.backblazeb2.com/file/EricZimmermanTools/net6/All_6.zip
    - skip_verify: True
    - makedirs: True

extract-all-6.zip:
  archive.extracted:
    - name: /tmp
    - source: /tmp/All_6.zip
    - enforce_toplevel: false
    - watch:
      - file: download-all-6.zip
    - require:
      - sls: sift.packages.dotnet

{% for tool in tools %}
extract-{{ tool }}:
  archive.extracted:
    - name: /opt/zimmermantools/
    - source: /tmp/{{ tool }}.zip
    - enforce_toplevel: false

{{ tool }}-wrapper:
  file.managed:
    - names:
      - /usr/local/bin/{{ tool }}
      - /usr/local/bin/{{ tool|lower }}
    - contents: |
        #!/bin/bash
        {% if tool|lower == "iisgeolocate" or tool|lower == "recmd" or tool|lower == "sqlecmd" %}
        dotnet /opt/zimmermantools/{{ tool }}/{{ tool }}.dll ${*}
        {% elif tool|lower == "evtxecmd" %}
        dotnet /opt/zimmermantools/EvtxeCmd/{{ tool }}.dll ${*}
        {% else %}
        dotnet /opt/zimmermantools/{{ tool }}.dll ${*}
        {% endif %}
    - mode: 755
    - replace: True
{% endfor %}
