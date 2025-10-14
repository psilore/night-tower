#!/usr/bin/env bash
#
# Generate an Ansible hosts.ini file from 1Password server items.
#
# This script fetches all server items from 1Password and outputs them in the format:
#   [host]
#   <host-name> ansible_user=<user>
#
# Usage: ./generate-hosts.sh
#

set -euo pipefail

#######################################
# Setup color formatting codes.
# Globals:
#   FMT_GREEN, FMT_RED, FMT_RESET, FMT_BOLD
# Arguments:
#   None
#######################################
setup_colors() {
  FMT_GREEN=$(printf '\033[32m')
  FMT_RED=$(printf '\033[31m')
  FMT_RESET=$(printf '\033[0m')
  FMT_BOLD=$(printf '\033[1m')
}

#######################################
# Format message with color and timestamp.
# Arguments:
#   $1 - color code
#   $2 - level label
#   $3+ - message
# Outputs:
#   Formatted message to stderr
#######################################
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
# Generate hosts.ini from 1Password server items.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   hosts.ini file in current directory
# Returns:
#   0 on success, non-zero on error
#######################################
generate_hosts_ini() {
  local output_file="hosts.ini"
  format_log "Generating hosts.ini..."
  echo "[host]" > "${output_file}"

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
    local line
    line=$(op item get "$id" --format=json | \
      jq -r '
        .fields as $fields |
        ($fields[] | select(.label=="hostname").value) as $host |
        ($fields[] | select(.label=="username").value) as $user |
        if $host and $user then
          "\($host) ansible_user=\($user)"
        else
          empty
        end
      ')
    if [[ -n "$line" ]]; then
      echo "$line" >> "${output_file}"
      found=1
    fi
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
  if generate_hosts_ini; then
    format_success "hosts.ini generated successfully."
  else
    format_error "Failed to generate hosts.ini."
    exit 1
  fi
}

main "$@"
