# AGENTS.md

Guidance for AI agents working in this repository.

## What this repo is

The SaltStack state tree that builds **SIFT** (SANS Investigative Forensic Toolkit) — a
DFIR workstation image. It is **not** an application: there is no build step, no test
suite in the usual sense, and no code that runs on this machine. Every `.sls` file is a
Salt state that installs or configures forensics tooling on a target Ubuntu host.

Installation is driven by [cast](https://github.com/ekristen/cast), which reads
`.cast.yml`, downloads a single-binary Salt, and applies the state tree:

```console
sudo cast install teamdfir/sift-saltstack
```

Upstream repo: `git@github.com:teamdfir/sift-saltstack.git`. Issues live in the
[SIFT repo](https://github.com/sans-dfir/sift/issues) prefixed `[SALTSTACK]`.

## Supported targets

`.cast.yml` is the source of truth: **Ubuntu 22.04 (jammy)** and **24.04 (noble)**, on
**amd64 and arm64**. Salt **3006** and **3007** are both tested. Focal (20.04) is EOL and
should not be added to new code paths, though stale references to it remain (see
[Known rough edges](#known-rough-edges)).

## Layout

```
.cast.yml                  cast manifest: modes, supported OS, pillar templates
VERSION                    vestigial (stale — see Known rough edges)
sift/
  desktop.sls  server.sls  the two real entrypoints
  vm.sls       pkgs.sls    legacy aliases -> desktop / server
  include-desktop.sls      desktop = server + config
  include-server.sls       server  = repos + python3-packages + packages + scripts
  repos/                   apt repos and PPAs (gift, sift, docker, microsoft, ubuntu-*)
  packages/                ~240 files, one apt package or .deb per file
    absent/                packages to remove (currently not wired in)
  python3-packages/        tools installed into per-tool virtualenvs under /opt
  perl-packages/           CPAN modules via cpanm
  scripts/                 tools installed from tarballs/zips/git, plus wrappers
  config/                  hostname, timezone, folders, samba, user/ (desktop only)
  files/                   static payloads served via salt://sift/files/...
  tests/                   aggregate states used by the weekly CI job only
.ci/                       Travis-era helper scripts (dead — see Known rough edges)
.github/workflows/         the CI that actually runs
```

Salt state IDs mirror paths: `sift/packages/foo.sls` → `sift.packages.foo`, and
`sift/packages/init.sls` → `sift.packages`.

## Entrypoints and the include graph

```
sift.desktop  -> sift.include-desktop -> sift.server -> sift.include-server -> repos
                                      -> sift.config                          python3-packages
                                                                              packages
                                                                              scripts
sift.server   -> sift.include-server
```

`cast` exposes these as modes: `desktop` (default) and `server`; `complete` and
`packages-only` are deprecated aliases.

## Conventions

Match the surrounding files. The tree is old and not uniformly consistent, so "what the
neighbours do" beats "what's globally most common."

### One tool per file

Each `.sls` under `packages/`, `python3-packages/`, `scripts/` installs exactly one tool.
Never bundle two tools into one file — CI tests changed states individually, so bundling
breaks the ability to test one thing.

### Register the new state in `init.sls`

Every directory's `init.sls` has a two-part structure that must be kept in sync:

```yaml
include:
  - sift.packages.newtool          # <- add here

sift-packages:
  test.nop:
    - name: sift-packages
    - require:
      - sls: sift.packages.newtool # <- and here
```

Adding to only one of the two lists is the most common mistake in this repo. A state
that is only in `include:` still runs, but the aggregate `test.nop` no longer gates on
it, so ordering guarantees quietly weaken.

Exception: a package that exists purely as a dependency of another state does not need
an `init.sls` entry — it gets pulled in transitively by whoever `include:`s it. Roughly
40 files under `packages/` are dependency-only this way (`libewf`, `swig`, `zlib1g-dev`,
…). Only add to `init.sls` when the tool should be installed on its own merit.

### Header comment block

Tool-facing states carry a metadata header (present on ~66 of 240 package files, and on
most newer additions). Include it on anything user-visible; skip it for pure build deps.

```yaml
# Name: AESKeyFinder
# Website: https://citp.princeton.edu/our-work/memory/
# Description: Find 128-bit and 256-bit AES keys in a memory image.
# Category:
# Author: Nadia Heninger, Alex Halderman
# License: Free, unknown license
# Notes: aeskeyfind
```

`Notes:` is the list of binaries the tool puts on `$PATH` — keep it accurate, it is the
only machine-readable record of what SIFT provides.

### State ID naming

Two conventions coexist in `packages/`: bare `<pkgname>:` (128 files, the older style)
and `sift-package-<pkgname>:` (91 files, the newer style). **Use the `sift-` prefix for
new files.** Do not mass-rename existing IDs — other states reference them by ID in
requisites, and renaming silently breaks those requisites.

Prefixes by directory:

| Directory          | State ID prefix                 |
| ------------------ | ------------------------------- |
| `packages/`        | `sift-package-<name>`           |
| `python3-packages/`| `sift-python3-package-<name>`   |
| `perl-packages/`   | `sift-perl-package-<name>`      |
| `scripts/`         | `sift-scripts-<name>`           |
| `repos/`           | `sift-<name>-repo`              |
| `config/`          | `config-<name>` / `sift-config-`|

### Pair every `include:` with a `require:`

Salt's `include:` makes states available but does **not** order them. Anything you
include as a dependency must also be required:

```yaml
include:
  - sift.repos.gift

sift-package-libewf:
  pkg.installed:
    - name: libewf
    - require:
      - sls: sift.repos.gift
```

Watch the spelling: the requisite is `require`, not `requires`, and `include` is not a
requisite. Salt state functions accept `**kwargs`, so a misspelled requisite is
**silently ignored** rather than raising — the state appears to work and the ordering
guarantee is simply gone. Two existing files have this bug (see
[Known rough edges](#known-rough-edges)).

### Pillars

Four pillar keys are read, all with defaults, all via `salt['pillar.get']`:

| Pillar          | Default            | Set by cast |
| --------------- | ------------------ | ----------- |
| `sift_user`     | `sansforensics`    | yes         |
| `sift_version`  | `stable`           | yes         |
| `sift_hostname` | `siftworkstation`  | no          |
| `sift_timezone` | `Etc/UTC`          | no          |

Declare them at the top of the file: `{%- set user = salt['pillar.get']('sift_user', 'sansforensics') -%}`.
`sift_version` selects the `stable` vs `dev` PPA in `repos/sift.sls` and `repos/gift.sls`.

### Architecture and release guards

arm64 support is partial and guarded explicitly. Two patterns are in use:

```jinja
{%- if grains["osarch"] == "aarch64" or grains["osarch"] == "arm64" -%}
```

for picking a different download URL/hash, and

```yaml
    - onlyif:
      - fun: match.grain
        tgt: 'osarch:amd64'
```

for skipping an amd64-only package entirely. Use `grains['oscodename']` (jammy/noble)
for release-specific branching. Never hardcode a codename or `amd64` in a URL — that was
the subject of several recent fixes.

### Version and hash pinning

Anything downloaded outside apt is pinned with an explicit version and SHA256, set as
Jinja variables at the top of the file, with per-arch hashes where needed:

```jinja
{# renovate: datasource=github-release-attachments depName=radareorg/radare2 #}
{%- set version = "5.9.6" -%}
{%- set base_url = "https://github.com/radareorg/radare2/releases/download/" -%}
{%- if grains["osarch"] == "aarch64" or grains["osarch"] == "arm64" -%}
{%- set hash = "c5b958a6..." -%}
{%- set filename = "radare2_" ~ version ~ "_arm64.deb" -%}
{%- else -%}
{%- set hash = "596c2b2e..." -%}
{%- set filename = "radare2_" ~ version ~ "_amd64.deb" -%}
{%- endif -%}
```

Downloads land in `/var/cache/sift/archives/` (preferred) via `file.managed` with
`source_hash: sha256={{ hash }}`, then `pkg.installed: - sources:` or
`archive.extracted` consumes them. Some older states use `/tmp` and clean up after
themselves; prefer `/var/cache/sift/archives/`.

`skip_verify: True` appears in four places and should be treated as a defect, not a
pattern to copy — this is a forensics distribution and unverified downloads undermine it.

The renovate config in `.github/renovate.json` auto-bumps pins, but only when the
annotation matches its regex exactly: a `{# renovate: datasource=... depName=... #}`
comment, then a line `set version = "..."`, then a line `set hash = "..."`. Only
`powershell.sls` and `radare2.sls` currently satisfy it; every other pinned file must be
bumped by hand. If you add a pinned download, add the annotation in that exact shape.

### Python tools go in their own virtualenv

Never `pip install` into the system Python. The pattern is a virtualenv under `/opt/<tool>`,
a `pip.installed` against its interpreter, and symlinks into `/usr/local/bin`:

```yaml
sift-python3-package-volatility3-venv:
  virtualenv.managed:
    - name: /opt/volatility3
    - venv_bin: /usr/bin/virtualenv
    - pip_pkgs:
      - pip>=24.1.3
      - setuptools>=70.0.0
      - wheel>=0.38.4
    - require:
      - sls: sift.packages.python3-virtualenv

sift-python3-package-volatility3:
  pip.installed:
    - name: volatility3
    - bin_env: /opt/volatility3/bin/python3
    - upgrade: True
    - require:
      - virtualenv: sift-python3-package-volatility3-venv

sift-python3-package-volatility3-symlink-vol:
  file.symlink:
    - name: /usr/local/bin/vol
    - target: /opt/volatility3/bin/vol
    - force: True
    - makedirs: False
    - require:
      - pip: sift-python3-package-volatility3
```

Pin git installs to a commit SHA (`git+https://…@<sha>`), not a branch.

### Repos use DEB822

New apt sources are written as DEB822 `.sources` files with an explicit `Signed-By`
keyring path, and the corresponding legacy `.list` file is removed with `file.absent`.
See `repos/microsoft.sls` for the full shape. PPAs still use `pkgrepo.managed` with
`ppa:` and a `keyid`.

### Static files

Payloads live under `sift/files/<tool>/` and are referenced as
`salt://sift/files/<tool>/<name>`. Use `file.managed` for one file, `file.recurse` for a
tree.

### No render-time network calls

`scripts/exiftool.sls` calls `salt['http.query']` during Jinja rendering to discover the
latest version and hash. Do not copy this: it makes the state non-reproducible, breaks
offline/air-gapped installs, and means a highstate can silently install a different
version than it did yesterday. Pin explicitly instead.

## Testing

There is nothing to run on this machine — states need a real Ubuntu target. Everything
happens in the same container image CI uses.

`.github/workflows/tests.yml` computes the set of changed `.sls` files on every push/PR
(skipping `init.sls`), turns each into a state name, and runs it standalone across the
matrix of Salt 3006/3007 × Ubuntu 22.04/24.04:

```console
salt-call --local -l info --file-root . --retcode-passthrough \
  --state-output=mixed state.sls sift.packages.newtool pillar="{sift_user: root}"
```

To reproduce locally, from the repo root (requires a working container runtime):

```console
docker run --rm -it -v "$PWD:/srv/salt" -w /srv/salt \
  ghcr.io/ekristen/cast-tools/saltstack-tester:22.04-3007 \
  salt-call --local -l info --file-root . --retcode-passthrough \
    --state-output=mixed state.sls sift.packages.newtool pillar='{sift_user: root}'
```

Swap the tag for `24.04-3007`, `22.04-3006`, etc. to cover the rest of the matrix.
`--file-root .` is what makes `sift.packages.newtool` resolve to `./sift/packages/newtool.sls`,
so the working directory must be the repo root.

Because CI only tests *changed* states in isolation, two classes of breakage get through:
a change to an `init.sls` (explicitly filtered out), and a change that breaks another
state's dependency ordering. Check both by hand when touching shared states like
`repos/*` or `packages/python3*`.

`.github/workflows/weekly-tests.yml` runs a fixed set of aggregate states
(`sift.packages.python3`, `sift.tests.gift`, `sift.config.user.pdfs`) on a Monday cron.

## Adding a tool — checklist

1. Pick the right directory: apt package or `.deb` → `packages/`; Python tool → `python3-packages/`;
   tarball/zip/git/wrapper script → `scripts/`; CPAN module → `perl-packages/`.
2. Create `<toolname>.sls` with the header comment block, filling in `Notes:` with the
   binaries it exposes.
3. Add every dependency to `include:` **and** to `require:`.
4. Pin version + SHA256 for non-apt downloads; add the renovate annotation in the exact
   documented shape.
5. Guard arch-specific and release-specific behaviour on grains.
6. Register in the directory's `init.sls` — both the `include:` list and the `test.nop`
   `require:` list — unless it is a dependency-only state.
7. Run the state in the tester container on 22.04 and 24.04 before opening a PR.

## Release

Releases are cut by cast, driven by `.cast.yml`, and tagged `vYYYY.MM.DD` (with
`-rcN` for prereleases). Signing keys live in `pgp.pub` and `cosign.pub`.

Do not use `.ci/tag-and-sign.sh` or `.ci/publish-draft.sh` — they are Travis-era, hardcode
an old GPG key ID and a `sans-dfir` repo path, push directly to `master`, and
`publish-draft.sh` has a malformed URL. They are kept only as history.

## Known rough edges

Pre-existing issues found while surveying the tree. None were introduced by recent work;
they are listed so you don't mistake them for conventions or "fix" them accidentally as
part of an unrelated change.

**Silently-ignored requisites** (Salt swallows misspelled requisite keys):

- `sift/include-desktop.sls:8` uses `- requires:` instead of `- require:`, so the desktop
  aggregate does not actually wait on `sift.server` or `sift.config`.
- `sift/scripts/exiftool.sls:43` uses `- include:` as a requisite on a `cmd.run`, so
  `perl Makefile.PL` is not ordered after `build-essential` and `perl` are installed.
  The same file's `sift-exiftool-makefile` also does not require `sift-exiftool-extracted`.
- `sift/desktop.sls:8` requires `sls: sift.include-server` where it means
  `sift.include-desktop`. It resolves transitively today, so it works by accident.

**Dead code — reachable from neither `sift.desktop` nor `sift.server`:**

- `sift/config/symlinks.sls` and `sift/config/rclocal.sls` are not in `config/init.sls`.
  `symlinks.sls` additionally requires `pkg: python-plaso`, a state ID that does not
  exist (the real one is `sift-package-python3-plaso`), so wiring it up as-is would fail.
- `sift/packages/absent/` (`binplist`, `unity-webapps-common`) is never included, so
  those intended removals never happen.
- `sift/python3-packages/defang.sls`, `sift/python3-packages/windowsprefetch.sls`,
  `sift/scripts/docker-compose.sls`, `sift/repos/ubuntu-tweak.sls`,
  `sift/perl-packages/dbd-sqlite.sls` are absent from their `init.sls`.
- `sift/packages/claude-code.sls` is unreachable **on purpose** — commit `34b42da`
  ("do not install claude by default"). Leave it that way.
- `sift/tests/*.sls` are intentionally out of the main graph; the weekly job calls them
  directly.

**Stale CI and tooling:**

- Everything in `.ci/` is Travis-era and non-functional: the scripts read `TRAVIS_COMMIT`,
  `TRAVIS_TAG`, and `TRAVIS_EVENT_TYPE`; `test.sh` invokes `./scripts/*.sh` from a
  directory that no longer exists; and they reference three different, now-defunct tester
  images (`sansdfir/sift-salt-tester`, `sift-salt-tester`,
  `ghcr.io/teamdfir/sift-saltstack-tester`). CI actually uses
  `ghcr.io/ekristen/cast-tools/saltstack-tester`. Several default to `DISTRO=focal`.
- `Dockerfile` (Ubuntu 18.04, `apt-key add`) and `Dockerfile.jammy3005` are referenced by
  nothing.
- `weekly-tests.yml` still matrixes Ubuntu 20.04, which `.cast.yml` does not support, and
  builds its image tag from `matrix.code` (`jammy-3006`) while `tests.yml` uses
  `matrix.os` (`22.04-3006`) — at most one of those tag formats can be right.
- `tests.yml` defines `matrix.code` in its `include:` block but never references it.

**Drifted metadata:**

- `VERSION` says `v2020.01.01-rc1`; the latest tag is `v2026.04.21`. Nothing reads
  `VERSION` any more except the dead release scripts.
- `README.md` lists Ubuntu 20.04 (deprecated) and 22.04; `.cast.yml` declares 22.04 and
  24.04. The README never mentions noble.
- `repos/sift.sls`, `repos/gift.sls`, `repos/openjdk.sls`, and `repos/dotnet-backports.sls`
  all set `keyserver: hkp://p80.pool.sks-keyservers.net:80`. The SKS pool was shut down in
  2021, so key fetches fall back to whatever apt/gpg does by default.

## Things not to do

- Don't bundle multiple tools into one `.sls` — it defeats per-state CI.
- Don't mass-rename state IDs to unify the two naming conventions; requisites reference
  IDs by name.
- Don't `pip install` or `cpanm` into system paths without the established venv pattern.
- Don't add `skip_verify: True` or unpinned downloads.
- Don't add render-time `salt['http.query']` lookups.
- Don't hardcode `amd64` or an Ubuntu codename — branch on grains.
- Don't change the default password hash in `sift/config/user/user.sls`; it is the
  documented, public SIFT default and tooling depends on it.
- Don't revive `.ci/` scripts or the `Dockerfile`s in passing.
