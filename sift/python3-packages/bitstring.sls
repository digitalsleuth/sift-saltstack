include:
  - sift.python3-packages.core

sift-python3-packages-bitstring:
  pip.installed:
    - name: bitstring
    - bin_env: /usr/bin/python3
    - require:
      - sls: sift.python3-packages.core
