#!/usr/bin/env bash
#
# Prune backup files, keeping only files from the last N days (default: 7).
#
# Usage:
#   prune-backups.sh [OPTIONS] [backup_dir] [glob_pattern] [days_to_keep]
#
# Options:
#   -h, --help            Show this help message and exit
#   -d, --backupdir DIR   Backup directory (overrides positional)
#   -p, --pattern PAT     File pattern to match (overrides positional)
#   -n, --days N          Number of days to keep (overrides positional)
#
# Arguments:
#   backup_dir        Directory containing backup files (required if -d/--backupdir not used)
#   glob_pattern      File pattern to match (default: '*', or use -p/--pattern)
#   days_to_keep      Number of days to keep (default: 7, or use -n/--days)
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
# Prune backup files older than N days.
# Arguments:
#   $1 - backup directory
#   $2 - glob pattern (optional, default: '*')
#   $3 - days to keep (optional, default: 7)
# Returns:
#   0 on success, non-zero on error
#######################################
prune_backups() {
  local backup_dir="$1"
  local pattern="${2:-*}"
  local days_to_keep="${3:-7}"
  if [[ ! -d "$backup_dir" ]]; then
    format_error "Backup directory '$backup_dir' does not exist."
    return 1
  fi
  if ! [[ "$days_to_keep" =~ ^[0-9]+$ ]]; then
    format_error "Days to keep must be a positive integer."
    return 1
  fi
  format_log "Pruning files in '$backup_dir' matching '$pattern' older than $days_to_keep days..."
  find "$backup_dir" -maxdepth 1 -type f -name "$pattern" -mtime +"$days_to_keep" -print -delete
  format_success "Pruning complete."
}



print_usage() {
  cat <<EOF
Usage:
  $0 [OPTIONS] [backup_dir] [glob_pattern] [days_to_keep]

Options:
  -h, --help            Show this help message and exit
  -d, --backupdir DIR   Backup directory (overrides positional)
  -p, --pattern PAT     File pattern to match (overrides positional)
  -n, --days N          Number of days to keep (overrides positional)

Arguments:
  backup_dir        Directory containing backup files (required if -d/--backupdir not used)
  glob_pattern      File pattern to match (default: '*', or use -p/--pattern)
  days_to_keep      Number of days to keep (default: 7, or use -n/--days)
EOF
}



main() {
  setup_colors

  local backup_dir=""
  local pattern="*"
  local days_to_keep="7"

  # Parse options
  local opts
  opts=$(getopt -o hd:p:n: --long help,backupdir:,pattern:,days: -n "$0" -- "$@") || {
    format_error "Failed to parse options."; exit 1;
  }
  eval set -- "$opts"

  while true; do
    case "$1" in
      -h|--help)
        print_usage
        exit 0
        ;;
      -d|--backupdir)
        backup_dir="$2"
        shift 2
        ;;
      -p|--pattern)
        pattern="$2"
        shift 2
        ;;
      -n|--days)
        days_to_keep="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      *)
        format_error "Unknown option: $1"; exit 1
        ;;
    esac
  done

  # Now $1, $2, $3 are positional arguments
  # Only set backup_dir/pattern/days_to_keep from positional if not set by option
  if [[ -z "$backup_dir" ]]; then
    if [[ $# -ge 1 ]]; then
      backup_dir="$1"
      shift
    fi
  fi
  if [[ "$pattern" == "*" && $# -ge 1 ]]; then
    pattern="$1"
    shift
  fi
  if [[ "$days_to_keep" == "7" && $# -ge 1 ]]; then
    days_to_keep="$1"
    shift
  fi

  if [[ -z "$backup_dir" ]]; then
    format_error "Missing required argument: backup_dir"
    print_usage
    exit 1
  fi
  prune_backups "$backup_dir" "$pattern" "$days_to_keep"
}

main "$@"
