# Dependency only -- not in packages/init.sls. Listed on mulder's apt line for strings,
# objdump and readelf; normally present via build-essential but not guaranteed on a
# server install.
sift-package-binutils:
  pkg.installed:
    - name: binutils
