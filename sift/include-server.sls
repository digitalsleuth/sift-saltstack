include:
  - sift.repos
  - sift.python3-packages
  - sift.packages
  - sift.scripts

sift-server-include:
  test.nop:
    - name: sift-server-include
    - require:
      - sls: sift.repos
      - sls: sift.python3-packages
      - sls: sift.packages
      - sls: sift.scripts
