# Name: aircrack-ng
# Website: https://www.aircrack-ng.org/
# Description: WiFi assessment tool suite
# Category: 
# Author: https://github.com/aircrack-ng/aircrack-ng/blob/master/AUTHORS
# License: https://www.aircrack-ng.org/license.html
# Notes: aircrack
# Warning: Only Supported on amd64 architecture 
sift-package-aircrack-ng:
  pkg.installed:
    - name: aircrack-ng
    - onlyif:
      - fun: match.grain
        tgt: 'osarch:amd64'

