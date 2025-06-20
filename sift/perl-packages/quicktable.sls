include:
  - sift.packages.perl
  - sift.packages.build-essential

sift-perl-package-quicktable:
  cmd.run:
    - name: cpanm --no-man-pages install HTML::QuickTable 
    - env:
      - PERL_MM_USE_DEFAULT: 1
    - require:
      - sls: sift.packages.perl
      - sls: sift.packages.build-essential
