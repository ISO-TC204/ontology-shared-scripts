#!/usr/bin/env bash
# Sync shared common files from ISO-TC204/ontology-shared-scripts into this repo.
#
# Usage:
#   bash scripts/sync-common.sh check              # exit 1 if consumer differs
#   bash scripts/sync-common.sh apply              # overwrite consumer files
#   bash scripts/sync-common.sh apply /path/to/shared
#
# Env:
#   SHARED_SCRIPTS_REF   git ref to fetch (default: main)
#   SHARED_SCRIPTS_REPO  owner/name (default: ISO-TC204/ontology-shared-scripts)

set -euo pipefail

MODE="${1:-check}"
SHARED_OVERRIDE="${2:-}"

SHARED_SCRIPTS_REPO="${SHARED_SCRIPTS_REPO:-ISO-TC204/ontology-shared-scripts}"
SHARED_SCRIPTS_REF="${SHARED_SCRIPTS_REF:-main}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMP_ROOT=""

cleanup() {
  if [[ -n "${TMP_ROOT}" && -d "${TMP_ROOT}" ]]; then
    rm -rf "${TMP_ROOT}"
  fi
}
trap cleanup EXIT

resolve_shared() {
  if [[ -n "${SHARED_OVERRIDE}" ]]; then
    SHARED_ROOT="$(cd "${SHARED_OVERRIDE}" && pwd)"
    return
  fi
  if [[ -n "${SHARED_SCRIPTS_DIR:-}" ]]; then
    SHARED_ROOT="$(cd "${SHARED_SCRIPTS_DIR}" && pwd)"
    return
  fi

  TMP_ROOT="$(mktemp -d)"
  SHARED_ROOT="${TMP_ROOT}/ontology-shared-scripts"
  echo "Fetching ${SHARED_SCRIPTS_REPO}@${SHARED_SCRIPTS_REF} ..."
  git clone --depth 1 --branch "${SHARED_SCRIPTS_REF}" \
    "https://github.com/${SHARED_SCRIPTS_REPO}.git" "${SHARED_ROOT}"
}

read_manifest() {
  local manifest="${SHARED_ROOT}/common/MANIFEST"
  if [[ ! -f "${manifest}" ]]; then
    echo "MANIFEST not found at ${manifest}" >&2
    exit 2
  fi
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue
    echo "${line}"
  done < "${manifest}"
}

apply_files() {
  local src dest src_path dest_path
  while IFS='|' read -r src dest; do
    src_path="${SHARED_ROOT}/${src}"
    dest_path="${REPO_ROOT}/${dest}"
    if [[ ! -f "${src_path}" ]]; then
      echo "Missing source: ${src_path}" >&2
      exit 2
    fi
    mkdir -p "$(dirname "${dest_path}")"
    cp "${src_path}" "${dest_path}"
    if [[ "${dest}" == *.sh ]]; then
      chmod +x "${dest_path}"
    fi
    echo "applied  ${dest}"
  done
}

check_files() {
  local src dest src_path dest_path drift=0
  while IFS='|' read -r src dest; do
    src_path="${SHARED_ROOT}/${src}"
    dest_path="${REPO_ROOT}/${dest}"
    if [[ ! -f "${src_path}" ]]; then
      echo "Missing source: ${src_path}" >&2
      exit 2
    fi
    if [[ ! -f "${dest_path}" ]]; then
      echo "MISSING  ${dest}"
      drift=1
      continue
    fi
    if ! cmp -s "${src_path}" "${dest_path}"; then
      echo "DRIFT    ${dest}"
      drift=1
    else
      echo "ok       ${dest}"
    fi
  done
  return "${drift}"
}

main() {
  case "${MODE}" in
    check|apply) ;;
    *)
      echo "Usage: $0 check|apply [path-to-shared-checkout]" >&2
      exit 2
      ;;
  esac

  resolve_shared
  echo "Shared root: ${SHARED_ROOT}"
  echo "Repo root:   ${REPO_ROOT}"

  if [[ "${MODE}" == "apply" ]]; then
    read_manifest | apply_files
    echo "Sync apply complete."
  else
    if read_manifest | check_files; then
      echo "Sync check passed."
    else
      echo "Sync check failed: consumer differs from ${SHARED_SCRIPTS_REPO}@${SHARED_SCRIPTS_REF}" >&2
      echo "Run: bash scripts/sync-common.sh apply" >&2
      exit 1
    fi
  fi
}

main
