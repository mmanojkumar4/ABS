#!/bin/bash

#Load Configuration
CONFIG_FILE="./backup.config"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo " Error: Configuration file not found: $CONFIG_FILE"
  exit 1
fi
source "$CONFIG_FILE"

#Logging Function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

#Prevent Multiple Runs
if [[ -f "$LOCK_FILE" ]]; then
  echo "Another backup process is already running."
  exit 1
fi
touch "$LOCK_FILE"



#Disk Space Check
check_space() {
  local available required
  available=$(df --output=avail -k "$BACKUP_DESTINATION" | tail -1)
  required=$(du -sk "$SOURCE_DIR" | awk '{print $1}')
  if (( available < required )); then
    log "ERROR: Not enough disk space for backup."
    rm -f "$LOCK_FILE"
    exit 1
  fi
}


#Email Simulation
send_email() {
  local subject="$1"
  local message="$2"
  echo "Subject: $subject" >> email.txt
  echo "$message" >> email.txt
  log "Email simulated: $subject"
}

#Verify Backup
verify_backup() {
  cd "$BACKUP_DESTINATION" || exit
  sha256sum -c "$1.sha256" >> "$LOG_FILE" 2>&1
  if [[ $? -eq 0 ]]; then
    log "INFO: Checksum verified successfully"
    send_email "Backup Success" "Backup $1 verified successfully."
  else
    log "ERROR: Backup verification failed"
    send_email "Backup Verification Failed" "Checksum failed for $1"
  fi
}

#Delete Old Backups
delete_old_backups() {
  cd "$BACKUP_DESTINATION" || exit 1
  log " Cleaning old backups..."

  daily_backups=($(ls -1t backup-*.tar.gz 2>/dev/null | head -n "$DAILY_KEEP"))
  weekly_backups=($(find . -type f -name "backup-*.tar.gz" -mtime -28 -printf "%f\n" 2>/dev/null | sort -r | head -n "$WEEKLY_KEEP"))
  monthly_backups=($(find . -type f -name "backup-*.tar.gz" -mtime +28 -printf "%f\n" 2>/dev/null | sort -r | head -n "$MONTHLY_KEEP"))

  keep_list=("${daily_backups[@]}" "${weekly_backups[@]}" "${monthly_backups[@]}")

  for file in backup-*.tar.gz; do
    if [[ ! " ${keep_list[@]} " =~ " ${file} " ]]; then
      rm -f "$file" "$file.sha256"
      log " Deleted old backup: $file"
    fi
  done
}

#Restore Function
restore_backup() {
  local backup_file="$1"
  local restore_dir="$2"

  if [[ ! -f "$BACKUP_DESTINATION/$backup_file" ]]; then
    echo " Backup file not found: $backup_file"
    exit 1
  fi

  mkdir -p "$restore_dir"
  tar -xzf "$BACKUP_DESTINATION/$backup_file" -C "$restore_dir"
  log "Restored backup $backup_file to $restore_dir"
}

#List Backups
list_backups() {
  log " Available Backups in $BACKUP_DESTINATION:"
  ls -lh "$BACKUP_DESTINATION"/backup-*.tar.gz 2>/dev/null || echo "No backups found."
}

#Create Backup (Full or Incremental)
create_backup() {
  local timestamp backup_name checksum_file snar_file
  timestamp=$(date +'%Y-%m-%d-%H%M')
  backup_name="backup-$timestamp.tar.gz"
  checksum_file="$backup_name.sha256"
  snar_file="$BACKUP_DESTINATION/backup.snar"

  log "INFO: Starting backup of $SOURCE_DIR"

  if [[ "$DRY_RUN" == true ]]; then
    echo " [DRY RUN] Would back up: $SOURCE_DIR"
    rm -f "$LOCK_FILE"
    exit 0
  fi

  mkdir -p "$BACKUP_DESTINATION"
  check_space

  local excludes=()
  IFS=',' read -ra patterns <<< "$EXCLUDE_PATTERNS"
  for pattern in "${patterns[@]}"; do
    excludes+=("--exclude=$pattern")
  done

  #  Incremental Backup: Only changed files since last run
  if [[ -f "$snar_file" ]]; then
    log "INFO: Performing incremental backup using $snar_file"
  else
    log "INFO: Performing first full backup"
  fi

  tar --listed-incremental="$snar_file" -czf "$BACKUP_DESTINATION/$backup_name" "${excludes[@]}" "$SOURCE_DIR" 2>>"$LOG_FILE"
  if [[ $? -ne 0 ]]; then
    log " ERROR: Failed to create backup."
    send_email "Backup Failed" "Backup of $SOURCE_DIR failed at $(date)"
    rm -f "$LOCK_FILE"
    exit 1
  fi

  sha256sum "$BACKUP_DESTINATION/$backup_name" > "$BACKUP_DESTINATION/$checksum_file"
  log " SUCCESS: Backup created: $backup_name"

  verify_backup "$backup_name"
}

#Command-line Parsing
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  SOURCE_DIR="$2"
elif [[ "$1" == "--restore" ]]; then
  BACKUP_FILE="$2"
  RESTORE_DIR="$3"
  restore_backup "$BACKUP_FILE" "$RESTORE_DIR"
  rm -f "$LOCK_FILE"
  exit 0
elif [[ "$1" == "--list" ]]; then
  list_backups
  rm -f "$LOCK_FILE"
  exit 0
else
  DRY_RUN=false
  SOURCE_DIR="$1"
fi

if [[ -z "$SOURCE_DIR" ]]; then
  echo " Usage: $0 [--dry-run] <source_directory>"
  rm -f "$LOCK_FILE"
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo " Source directory not found: $SOURCE_DIR"
  rm -f "$LOCK_FILE"
  exit 1
fi

#MAIN EXECUTION
create_backup
delete_old_backups

#Cleanup
rm -f "$LOCK_FILE"
