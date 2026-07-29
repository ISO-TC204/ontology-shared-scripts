# ontology-shared-scripts

Scripts and **common files** shared by ITS ontology repositories so checks and
repo chrome stay consistent.

## Contents

| Path | Purpose |
|------|---------|
| `scripts/versioning.py` | VERSION / RELEASES validation and suggestions |
| `scripts/sync-common.sh` | Copy or check common files into an ontology repo |
| `common/` | Policy, docs chrome, MkDocs defaults, Cursor shared rules |
| `.github/workflows/` | Reusable workflows (`validate-version`, release, deploy, sync, …) |

## Using reusable workflows

Ontology repos keep thin callers, for example:

```yaml
jobs:
  validate-version:
    uses: ISO-TC204/ontology-shared-scripts/.github/workflows/validate-version.yml@main
```

## Syncing common files

Canonical copies live under `common/` (plus `scripts/versioning.py` and
`scripts/sync-common.sh`). The map is `common/MANIFEST`.

Always run from the **ontology repo root** (not from this shared-scripts tree):

```bash
cd /path/to/ontology-its-location

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

Caller workflow:

```yaml
name: Sync common files
on:
  pull_request:
  workflow_dispatch:
jobs:
  sync-common-files:
    uses: ISO-TC204/ontology-shared-scripts/.github/workflows/sync-common-files.yml@main
    with:
      mode: check
```

### Per-repo files (not synced)

Keep these local to each ontology:

- Ontology / SHACL Turtle under `docs/`
- `VERSION`, `RELEASES`, project `README.md`
- Identity `mkdocs.yml` (`INHERIT: mkdocs.common.yml` + site_name / urls / nav)
- Thin `.github/workflows/*` callers
- `.cursor/rules.md` specialty overlay (shared body is `.cursor/rules-common.md`)

## MkDocs

Shared theme/plugins/extensions live in `common/mkdocs.common.yml`. Each site:

```yaml
INHERIT: mkdocs.common.yml
site_name: ITS Ontology - Example
repo_url: https://github.com/ISO-TC204/ontology-its-example
site_url: https://isotc204.org/ontology-its-example
nav:
- Home: index.md
```
