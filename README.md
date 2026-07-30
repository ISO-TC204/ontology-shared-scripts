# ontology-shared-scripts

This repository contains scripts and **common files** shared by ITS ontology repositories so that checks can be made to ensure that ontology repositories stay up-to-date with the latest versions and go through proper validation checks, including ensuring that files are properly version stamped.

## Contents

| Path | Purpose |
| ---- | ------- |
| `.github/workflows/` | Shared workflows called by ontology repository workflows to ensure that all repositories run the latest version (`workflow_call` only) |
| `scripts/versioning.py` | Shared script called during the GitHub validation of a Pull Request to ensure that the VERSION and RELEASES files are valid and to make suggestions. The local copy of the repo script can be called from the Terminal so that the developer can ensure that all requirements are met before committing by running `python scripts/versioning.py suggest` or `python scripts/versioning.py validate`. |
| `scripts/sync-common.sh` | Shared script called during the GitHub validation of a Pull Request to ensure that common files that should be in every ontology repository are up to date. The local copy of the repo script can be called from the Terminal so that the developer can ensure that all requirements are met before committing by running `bash scripts/sync-common.sh check` or `bash scripts/sync-common.sh apply`. |
| `common/` | Policy, docs, MkDocs defaults, Cursor shared rules, thin workflow callers, etc. Most of these are contained in the MAIFEST, which is used by sync-common.sh to ensure that the files are up to date. |

## Using reusable workflows

Canonical **thin callers** live under `common/.github/workflows/` and sync into
each ontology repo via `MANIFEST` and `sync-common.sh`. They invoke the shared workflows that live at `ISO-TC204/ontology-shared-scripts/.github/workflows/`, for example:

```yaml
jobs:
  validate-version:
    uses: ISO-TC204/ontology-shared-scripts/.github/workflows/validate-version.yml@main
```

Edit the shared workflows stored in `ISO-TC204/ontology-shared-scripts/.github/workflows/` and the callers stored in `common/.github/workflows/`, and then copy to individual ontology repos with the next sync.

## Syncing common files

Canonical copies live under `common/` (plus `scripts/versioning.py` and
`scripts/sync-common.sh`). The map is `common/MANIFEST`.

Always run from the **ontology repo root** (not from this shared-scripts tree):

```bash
cd /path/to/ontology-*

# overwrite local copies from shared @main
bash scripts/sync-common.sh apply

# or against a local checkout of this repo
bash scripts/sync-common.sh apply /path/to/ontology-shared-scripts

# CI / pre-PR drift check
bash scripts/sync-common.sh check
```

If you invoke the script that lives *inside* `ontology-shared-scripts`, set the consumer explicitly:

```bash
CONSUMER_ROOT=/path/to/ontology-its-location \
  bash /path/to/ontology-shared-scripts/scripts/sync-common.sh check
```

The script refuses to treat `ontology-shared-scripts` itself as the consumer.

The sync CI caller (`common/.github/workflows/sync-common-files.yml`) calls the
reusable workflow, which always copies `scripts/sync-common.sh` from this repo
before running — so check/apply does not depend on an already-synced script.

### Per-repo files (not synced)

Keep these local to each ontology:

- Ontology / SHACL Turtle under `docs/`
- `VERSION`, `RELEASES`, project `README.md`
- Identity `mkdocs.yml` (`INHERIT: mkdocs.common.yml` + site_name / urls / nav)
- `.cursor/rules.md` specialty overlay (shared body is `.cursor/rules-common.md`)

## MkDocs

Shared theme/plugins/extensions live in `common/mkdocs.common.yml`. Each site:

```yaml
INHERIT: mkdocs.common.yml
site_name: ITS Ontology - Example
repo_url: https://github.com/ISO-TC204/ontology-*
site_url: https://isotc204.org/ontology-*
nav:
- Home: index.md
```
