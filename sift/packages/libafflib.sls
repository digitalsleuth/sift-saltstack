# Name: AFFLIBv3
# Website: https://github.com/sshock/AFFLIBv3
# Description: AFF is an open and extensible file format to store disk images
# Category:
# Author: Simson L. Garfinkel / Phillip Hellewell et al (https://github.com/sshock/AFFLIBv3/blob/master/AUTHORS)
# License: Multiple Licenses (https://github.com/sshock/AFFLIBv3/blob/master/COPYING)
# Notes:

{% if grains['oscodename'] == 'jammy' %}
  {% set package = 'libafflib0v5' %}
{% elif grains['oscodename'] == 'noble' %}
  {% set package = 'libafflib0t64' %}
{% endif %}

sift-package-libafflib:
  pkg.installed:
    - name: {{ package }}
