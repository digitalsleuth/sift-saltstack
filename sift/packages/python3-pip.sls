include:
  - sift.packages.python3

sift-package-python3-pip:
  pkg.installed:
    - name: python3-pip
    - require:
      - sls: sift.packages.python3
