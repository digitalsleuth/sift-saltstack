include:
  - sift.python3-packages.pip

sift-python3-packages-pefile:
  pip.installed:
    - name: pefile
    - bin_env: /usr/bin/python3
    - require:
      - sls: sift.python3-packages.pip

