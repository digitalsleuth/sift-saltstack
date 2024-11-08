include:
  - sift.python3-packages.analyzemft
  - sift.python3-packages.pip
  - sift.python3-packages.python3-keyring
  - sift.python3-packages.argparse
  - sift.python3-packages.bitstring
  - sift.python3-packages.colorama
  - sift.python3-packages.geoip2
  - sift.python3-packages.ioc_writer
###  - sift.python3-packages.imagemounter
  - sift.python3-packages.keyrings-alt
  - sift.python3-packages.lxml
  - sift.python3-packages.machinae
  - sift.python3-packages.pefile
  - sift.python3-packages.pillow
  - sift.python3-packages.pyhindsight
  - sift.python3-packages.python-dateutil
  - sift.python3-packages.python-evtx
  - sift.python3-packages.python-magic
  - sift.python3-packages.python-registry
  - sift.python3-packages.setuptools
  - sift.python3-packages.setuptools-rust
  - sift.python3-packages.six
  - sift.python3-packages.stix-validator
  - sift.python3-packages.stix
  - sift.python3-packages.virustotal-api
  - sift.python3-packages.wheel
  - sift.python3-packages.yara-python

sift-python3-packages:
  test.nop:
    - name: sift-python3-packages
    - require:
      - sls: sift.python3-packages.analyzemft
      - sls: sift.python3-packages.pip
      - sls: sift.python3-packages.python3-keyring
      - sls: sift.python3-packages.argparse
      - sls: sift.python3-packages.bitstring
      - sls: sift.python3-packages.colorama
      - sls: sift.python3-packages.geoip2
      - sls: sift.python3-packages.ioc_writer
###      - sls: sift.python3-packages.imagemounter
      - sls: sift.python3-packages.keyrings-alt
      - sls: sift.python3-packages.lxml
      - sls: sift.python3-packages.machinae
      - sls: sift.python3-packages.pefile
      - sls: sift.python3-packages.pillow
      - sls: sift.python3-packages.pyhindsight
      - sls: sift.python3-packages.python-dateutil
      - sls: sift.python3-packages.python-evtx
      - sls: sift.python3-packages.python-magic
      - sls: sift.python3-packages.python-registry
      - sls: sift.python3-packages.setuptools
      - sls: sift.python3-packages.setuptools-rust
      - sls: sift.python3-packages.six
      - sls: sift.python3-packages.stix-validator
      - sls: sift.python3-packages.stix
      - sls: sift.python3-packages.virustotal-api
      - sls: sift.python3-packages.wheel
      - sls: sift.python3-packages.yara-python
