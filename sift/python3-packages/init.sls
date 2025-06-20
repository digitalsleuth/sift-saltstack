include:
  - sift.python3-packages.analyzemft
  - sift.python3-packages.python3-keyring
  - sift.python3-packages.hindsight
  - sift.python3-packages.ioc-writer
  - sift.python3-packages.imagemounter
  - sift.python3-packages.indxparse
  - sift.python3-packages.java-idx-parser
  - sift.python3-packages.mac-apt
  - sift.python3-packages.machinae
  - sift.python3-packages.page-brute
  - sift.python3-packages.pe-carver
  - sift.python3-packages.pe-scanner
  - sift.python3-packages.python-evtx
  - sift.python3-packages.sqlite-carver
  - sift.python3-packages.stix-validator
  - sift.python3-packages.usbdeviceforensics
  - sift.python3-packages.usnparser

sift-python3-packages:
  test.nop:
    - name: sift-python3-packages
    - require:
      - sls: sift.python3-packages.analyzemft
      - sls: sift.python3-packages.python3-keyring
      - sls: sift.python3-packages.hindsight
      - sls: sift.python3-packages.ioc-writer
      - sls: sift.python3-packages.imagemounter
      - sls: sift.python3-packages.indxparse
      - sls: sift.python3-packages.java-idx-parser
      - sls: sift.python3-packages.mac-apt
      - sls: sift.python3-packages.machinae
      - sls: sift.python3-packages.page-brute
      - sls: sift.python3-packages.pe-carver
      - sls: sift.python3-packages.pe-scanner
      - sls: sift.python3-packages.python-evtx
      - sls: sift.python3-packages.sqlite-carver
      - sls: sift.python3-packages.stix-validator
      - sls: sift.python3-packages.usbdeviceforensics
      - sls: sift.python3-packages.usnparser