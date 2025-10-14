#!/usr/bin/env bash
#
# Backup n8n workflows and credentials using the n8n CLI inside a Docker container.
#

set -euo pipefail

# --- CONSTANTS ---
readonly N8N_CONTAINER_NAME="n8n"
readonly HOST_DATA_DIR="./n8n/data"
readonly BACKUP_DIR_CONTAINER="/data/cli_backups"
readonly BACKUP_ARCHIVE_HOST_DIR="/var/backups/n8n_cli"

# --- DYNAMIC VARIABLES ---
ARCHIVE_FILENAME="n8n_cli_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

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

#######################################
# Format error message.
# Arguments:
#   Error message
# Outputs:
#   Formatted error to stderr
#######################################
format_error() {
  _format_msg "${FMT_RED}${FMT_BOLD}" "ERROR" "$@"
}

#######################################
# Format success message.
# Arguments:
#   Success message
# Outputs:
#   Formatted success to stderr
#######################################
format_success() {
  _format_msg "${FMT_GREEN}${FMT_BOLD}" "SUCCESS" "$@"
}

#######################################
# Format info message.
# Arguments:
#   Info message
# Outputs:
#   Formatted info to stderr
#######################################
format_log() {
  _format_msg "${FMT_BOLD}" "INFO" "$@"
}

#######################################
# Check if command exists.
# Arguments:
#   Command name
# Returns:
#   0 if exists, 1 if not
#######################################
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

#######################################
# Prepare host directories and clean up old files.
# Globals:
#   HOST_DATA_DIR, BACKUP_ARCHIVE_HOST_DIR
# Returns:
#   None
#######################################
prepare_host_dirs() {
  mkdir -p "${HOST_DATA_DIR}/cli_backups"
  mkdir -p "${BACKUP_ARCHIVE_HOST_DIR}"
  rm -rf "${HOST_DATA_DIR}/cli_backups/*"
}

#######################################
# Export workflows and credentials from n8n container.
# Globals:
#   N8N_CONTAINER_NAME, BACKUP_DIR_CONTAINER, HOST_DATA_DIR
# Returns:
#   0 on success, non-zero on error
#######################################
export_n8n_data() {
  format_log "Exporting workflows..."
  if ! docker exec -u node "${N8N_CONTAINER_NAME}" n8n export:workflow --backup --output="${BACKUP_DIR_CONTAINER}/workflows/"; then
    format_error "Workflow export failed."
    return 1
  fi
  format_log "Exporting credentials..."
  if ! docker exec -u node "${N8N_CONTAINER_NAME}" n8n export:credentials --backup --decrypted --output="${BACKUP_DIR_CONTAINER}/credentials/"; then
    format_error "Credentials export failed."
    return 1
  fi
  format_success "Workflows and credentials exported as JSON files."
}

#######################################
# Archive exported files on the host.
# Globals:
#   HOST_DATA_DIR, BACKUP_ARCHIVE_HOST_DIR, ARCHIVE_FILENAME
# Returns:
#   0 on success, non-zero on error
#######################################
archive_exports() {
  format_log "Creating final archive..."
  if tar -czf "${BACKUP_ARCHIVE_HOST_DIR}/${ARCHIVE_FILENAME}" -C "${HOST_DATA_DIR}/cli_backups" .; then
    format_success "Backup archive created at ${BACKUP_ARCHIVE_HOST_DIR}/${ARCHIVE_FILENAME}"
  else
    format_error "Failed to create archive."
    return 1
  fi
}

#######################################
# Main program logic.
# Returns:
#   0 on success, non-zero on error
#######################################
main() {
  setup_colors
  format_log "Starting CLI-based backup of n8n workflows and credentials..."
  prepare_host_dirs
  if ! export_n8n_data; then
    exit 1
  fi
  if ! archive_exports; then
    exit 1
  fi
  format_success "Backup script finished."
}

main "$@"