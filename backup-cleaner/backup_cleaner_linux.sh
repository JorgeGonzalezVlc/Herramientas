#!/usr/bin/env bash

# ============================================================
# Backup Cleaner
# Recursively deletes files and empty directories
# only when BOTH date criteria are met
# ============================================================

set -o nounset
set -o pipefail

ROOT_PATH=""
CREATED_BEFORE=""
MODIFIED_AFTER=""
DRY_RUN=true

deleted=0
skipped=0
errors=0

usage() {
  cat <<EOF
Usage:
  ./clean-old-backups.sh --path <directory> --created-before <YYYY-MM-DD> --modified-after <YYYY-MM-DD> [--delete]

Description:
  Recursively scans a directory and deletes items only if BOTH conditions are met:

    - Creation date is older than the specified date
    - Modification date is newer than the specified date

Deletion rules:
  - Files are deleted only if they meet both criteria
  - Directories are deleted only if they meet both criteria AND are empty

Options:
  --path              Root directory to scan
  --created-before    Delete items created before this date
  --modified-after    Delete items modified after this date
  --delete            Perform real deletion (default is simulation)
  --help              Show this help message
EOF
}

log() {
  printf '%s\n' "$1"
}

error() {
  printf '[ERROR] %s\n' "$1" >&2
}

to_epoch() {
  date -d "$1" +%s 2>/dev/null
}

get_birth_epoch() {
  stat -c %W "$1" 2>/dev/null || echo "-1"
}

get_mtime_epoch() {
  stat -c %Y "$1" 2>/dev/null
}

should_delete() {
  local item="$1"
  local created_before_epoch="$2"
  local modified_after_epoch="$3"

  local birth_epoch
  local mtime_epoch

  birth_epoch=$(get_birth_epoch "$item")
  mtime_epoch=$(get_mtime_epoch "$item")

  # Si no hay fecha de creación disponible, se omite por seguridad
  if [[ -z "$birth_epoch" || "$birth_epoch" == "-1" || "$birth_epoch" == "0" ]]; then
    return 1
  fi

  if [[ -z "$mtime_epoch" ]]; then
    return 1
  fi

  if (( birth_epoch < created_before_epoch && mtime_epoch > modified_after_epoch )); then
    return 0
  fi

  return 1
}

delete_file() {
  local file="$1"

  if [[ "$DRY_RUN" == "true" ]]; then
    log "[SIMULATION] Would delete file: $file"
    return 0
  fi

  rm -f -- "$file"
}

delete_dir() {
  local dir="$1"

  if [[ "$DRY_RUN" == "true" ]]; then
    log "[SIMULATION] Would delete empty directory: $dir"
    return 0
  fi

  rmdir -- "$dir"
}

is_directory_empty() {
  local dir="$1"

  if find "$dir" -mindepth 1 -maxdepth 1 | read -r; then
    return 1
  fi

  return 0
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --path)
        ROOT_PATH="$2"
        shift 2
        ;;
      --created-before)
        CREATED_BEFORE="$2"
        shift 2
        ;;
      --modified-after)
        MODIFIED_AFTER="$2"
        shift 2
        ;;
      --delete)
        DRY_RUN=false
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

main() {
  parse_args "$@"

  if [[ -z "$ROOT_PATH" || -z "$CREATED_BEFORE" || -z "$MODIFIED_AFTER" ]]; then
    error "Missing required arguments."
    usage
    exit 1
  fi

  if [[ ! -d "$ROOT_PATH" ]]; then
    error "Directory does not exist: $ROOT_PATH"
    exit 1
  fi

  local created_before_epoch
  local modified_after_epoch

  created_before_epoch=$(to_epoch "$CREATED_BEFORE")
  if [[ -z "$created_before_epoch" ]]; then
    error "Invalid date in --created-before: $CREATED_BEFORE"
    exit 1
  fi

  modified_after_epoch=$(to_epoch "$MODIFIED_AFTER")
  if [[ -z "$modified_after_epoch" ]]; then
    error "Invalid date in --modified-after: $MODIFIED_AFTER"
    exit 1
  fi

  log "Root path: $ROOT_PATH"
  log "Delete if creation < $CREATED_BEFORE AND modification > $MODIFIED_AFTER"
  log ""

  log "Processing files..."
  while IFS= read -r -d '' file; do
    if should_delete "$file" "$created_before_epoch" "$modified_after_epoch"; then
      if delete_file "$file"; then
        ((deleted+=1))
      else
        error "Could not delete file: $file"
        ((errors+=1))
      fi
    else
      ((skipped+=1))
    fi
  done < <(find "$ROOT_PATH" -mindepth 1 -type f -print0)

  log ""
  log "Processing directories..."
  while IFS= read -r -d '' dir; do
    if should_delete "$dir" "$created_before_epoch" "$modified_after_epoch"; then
      if is_directory_empty "$dir"; then
        if delete_dir "$dir"; then
          ((deleted+=1))
        else
          error "Could not delete directory: $dir"
          ((errors+=1))
        fi
      else
        log "[SKIPPED] Directory not empty: $dir"
        ((skipped+=1))
      fi
    else
      ((skipped+=1))
    fi
  done < <(find "$ROOT_PATH" -mindepth 1 -type d -depth -print0)

  log ""
  log "Summary"
  log "Deleted: $deleted"
  log "Skipped: $skipped"
  log "Errors : $errors"

  if [[ "$DRY_RUN" == "true" ]]; then
    log ""
    log "Simulation mode enabled. Use --delete to perform actual deletion."
  fi
}

main "$@"
