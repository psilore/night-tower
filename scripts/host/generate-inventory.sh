#!/usr/bin/env bash
#
# Generate an Ansible inventory.yaml file from 1Password server items.
#
# This script fetches all server items from 1Password and outputs them in YAML format:
#   all:
#     hosts:
#       <hostlabel>:
#         ansible_host: <hostname>
#         ansible_user: <ansibleuser>
#
# Usage: ./generate-inventory.sh
#

set -euo pipefail

#######################################
# Setup color formatting codes.
setup_colors() {
  FMT_GREEN=$(printf '\033[32m')
  FMT_RED=$(printf '\033[31m')
  FMT_RESET=$(printf '\033[0m')
  FMT_BOLD=$(printf '\033[1m')
}

#######################################
# Format message with color and timestamp.
_format_msg() {
  local color="$1"
  local level="$2"
  shift 2
  local date
  date="$(date +"%b %d %H:%M:%S")"
  printf "%s%s [%s]: %s%s\n" "$color" "$date" "$level" "$*" "$FMT_RESET" >&2
}

format_log()    { _format_msg "${FMT_BOLD}" "INFO" "$@"; }
format_success(){ _format_msg "${FMT_GREEN}${FMT_BOLD}" "SUCCESS" "$@"; }
format_error()  { _format_msg "${FMT_RED}${FMT_BOLD}" "ERROR" "$@"; }

#######################################
# Generate inventory.yaml from 1Password server items using yq (Python jq wrapper) for JSON-to-YAML conversion.
generate_inventory_yaml() {
  local output_file="ansible/inventory.yaml"
  format_log "Generating inventory.yaml using yq (Python jq wrapper)..."
  echo "all:" > "$output_file"
  echo "  hosts:" >> "$output_file"

  local ids
  if ! ids=$(op item list --categories=server --format=json | jq -r '.[].id'); then
    format_error "Failed to list server items from 1Password."
    return 1
  fi

  local found=0
  while read -r id; do
    if [[ -z "$id" ]]; then
      continue
    fi
    op item get "$id" --format=json | jq -c '
      .fields as $fields |
      {hostlabel: ($fields[] | select(.label=="hostlabel").value),
       ansible_host: ($fields[] | select(.label=="hostname").value),
       ansible_user: ($fields[] | select(.label=="ansibleuser").value)}
      | select(.hostlabel and .ansible_host and .ansible_user)
    ' | while read -r json; do
      if [[ -n "$json" ]]; then
        hostlabel=$(echo "$json" | jq -r '.hostlabel')
        # ansible_host and ansible_user are extracted but not logged
        echo "$json" | jq 'del(.hostlabel)' | yq -y '.' | sed 's/^/      /' | sed "1s/^/    $hostlabel:\n/" >> "$output_file"
        echo processed
      fi
    done | grep -q processed && found=1
  done < <(printf '%s\n' "$ids")

  if [[ "$found" -eq 0 ]]; then
    format_error "No valid server entries found in 1Password."
    return 1
  fi
  return 0
}

main() {
  setup_colors
  if ! command -v op >/dev/null 2>&1; then
    format_error "1Password CLI (op) is not installed."
    exit 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    format_error "jq is not installed."
    exit 1
  fi
  if ! command -v yq >/dev/null 2>&1; then
    format_error "yq is not installed."
    exit 1
  fi
  if generate_inventory_yaml; then
    format_success "inventory.yaml generated successfully."
  else
    format_error "Failed to generate inventory.yaml."
    exit 1
  fi
}

main "$@"
