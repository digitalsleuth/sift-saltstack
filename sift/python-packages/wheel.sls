include:
  - sift.packages.python2-pip

sift-python-packages-wheel:
  pip.installed:
    - name: wheel
    - bin_env: /usr/bin/python2
    - upgrade: True
    - require:
      - sls: sift.packages.python2-pip
