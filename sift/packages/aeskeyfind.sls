# Name: AESKeyFinder
# Website: https://citp.princeton.edu/our-work/memory/
# Description: Find 128-bit and 256-bit AES keys in a memory image.
# Category: 
# Author: Nadia Heninger, Alex Halderman
# License: Free, unknown license
# Notes: aeskeyfind

sift-package-aeskeyfind:
  pkg.installed:
    - name: aeskeyfind
    - onlyif:
      - fun: match.grain
        tgt: 'osarch:amd64'

