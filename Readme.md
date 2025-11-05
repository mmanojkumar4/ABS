#  **Project Name : Automated Backup System**

This project is a **Automated backup system** that helps protect important data by creating and managing regular backups. It is Bash-based automated backup system.

The script can:

* Automatically back up your selected folders
* Support incremental and full backups
* Clean old backups using rotation logic
* Verify integrity of each backup using checksum
* Simulate email notifications after every backup
* Provide dry-run, list, and restore functions

It’s useful for automating data protection, reducing manual work, and keeping system storage organized.

---

##  **Main Features and Functions**

### **1️ Configuration File Loading**

**Function:**

```bash
CONFIG_FILE="./backup.config"
source "$CONFIG_FILE"
```

All variables like destination, log paths, and retention policy are stored in **`backup.config`**.
Keeps the script flexible and easy to modify.

---

### **2️ Logging System**

**Function:**

```bash
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}
```

Every action is logged into **`backup.log`** with timestamps.
This helps in debugging and tracking backup operations.

---

### **3️ Prevent Multiple Runs**

**Lock File Mechanism:**

```bash
if [[ -f "$LOCK_FILE" ]]; then
  echo "Another backup process is already running."
  exit 1
fi
```

The script checks if another backup is already running using a lock file.
If found, it exits safely.

---

### **4️ Disk Space Check**

**Function:**

```bash
check_space()
```

Checks available space in destination before backing up.
If space is low, it logs an error and exits.

```bash
available=$(df --output=avail -k "$BACKUP_DESTINATION" | tail -1)
required=$(du -sk "$SOURCE_DIR" | awk '{print $1}')
```

 Prevents partial or failed backups due to storage shortage.

---

### **5️ Backup Creation (Main Feature)**

**Function:**

```bash
create_backup()
```

Creates both **Full** and **Incremental** backups using `tar`.

*  **Full backup** (first time)
*  **Incremental backup** (next runs – only changed files)

```bash
tar --listed-incremental=backup.snar -czf backup-YYYY-MM-DD-HHMM.tar.gz "$SOURCE_DIR"
```

Backup files are named like `backup-2025-11-04-0857.tar.gz`. 
A `.snar` file (`backup.snar`) keeps track of previous backups.
Also supports **dry-run mode** to simulate backups.

---

### **6️ Checksum Verification**

**Function:**

```bash
verify_backup()
```

After creating a backup, a checksum (`SHA256`) file is generated and verified:

```bash
sha256sum "$BACKUP_DESTINATION/$backup_name" > "$BACKUP_DESTINATION/$checksum_file"
sha256sum -c "$1.sha256"
```

Ensures data integrity and confirms the backup isn’t corrupted.

---

### **7️ Automatic Old Backup Deletion**

**Function:**

```bash
delete_old_backups()
```

Implements **backup rotation** — keeps only recent backups.

```bash
find . -type f -name "backup-*.tar.gz" -mtime +28 -delete
```

 Keeps storage optimized and clean.

---

### **8️ List Available Backups**

**Function:**

```bash
list_backups()
```

Displays all backup files with size and date.

```bash
ls -lh "$BACKUP_DESTINATION"/backup-*.tar.gz
```

Useful for quickly viewing available archives.

---

### **9️ Restore Backup**

**Function:**

```bash
restore_backup()
```

Restores the chosen backup file into a given directory.

```bash
tar -xzf "$BACKUP_DESTINATION/$backup_file" -C "$restore_dir"
```

Allows you to recover data anytime.

---

---

###  10 **Automatic Old Backup Deletion (Rotation System)**

**Function:**

```bash
delete_old_backups()
```

This function automatically **deletes old backups** to keep your storage clean and organized.
It applies **retention rules** defined in your `backup.config` file.

####  How It Works:

1. **Daily backups:** Keeps the latest `DAILY_KEEP` backups.
2. **Weekly backups:** Keeps only 1 per week (based on `WEEKLY_KEEP`).
3. **Monthly backups:** Keeps 1 per month (based on `MONTHLY_KEEP`).
4. **Older backups beyond these limits are deleted automatically.**

####  Commands Used:

```bash
daily_backups=($(ls -1t backup-*.tar.gz 2>/dev/null | head -n "$DAILY_KEEP"))
weekly_backups=($(find . -type f -name "backup-*.tar.gz" -mtime -28 -printf "%f\n" 2>/dev/null | sort -r | head -n "$WEEKLY_KEEP"))
monthly_backups=($(find . -type f -name "backup-*.tar.gz" -mtime +28 -printf "%f\n" 2>/dev/null | sort -r | head -n "$MONTHLY_KEEP"))
```

####  Log Example:

```
[2025-11-04 08:57:54] 🧹 Cleaning old backups...
[2025-11-04 08:57:54] Deleted old backup: backup-2025-09-01-0930.tar.gz
[2025-11-04 08:57:54] Deleted old backup: backup-2025-08-15-0915.tar.gz
```

#### Why It’s Useful:

* Keeps only recent backups, saving disk space.
* Prevents the destination folder from growing too large.
* Works automatically — no manual cleanup needed.

--

















##  **Bonus Features**

### **Dry Run Mode**

**Command:**

```bash
./backup.sh --dry-run /path/to/source
```

Simulates the backup process without creating any files.
Helpful for testing and validation.

---

### **Email Simulation**

**Function:**

```bash
send_email()
log "Email simulated: Backup Success"
```

Instead of sending real emails, it logs simulated messages into `email.txt`.

---

### **Error Handling**

Handled with clear messages and exit codes for:

* Invalid source folder
* Missing config file
* No disk space

Prevents crashes and provides user-friendly output.

---

### **Incremental Backups with .snar File**

Uses:

```bash
tar --listed-incremental
```

Backs up only files changed since the last run — saving space and time.

---

### **Configurable Exclusions**

Allows excluding unwanted patterns like `.git` or `.cache`:

```bash
EXCLUDE_PATTERNS=".git,node_modules,.cache"
```

---

##  **How It Works (Internal Logic)**

1. Load `backup.config` for setup
2. Lock file ensures single process
3. Run `check_space()` before creating backup
4. Create `.tar.gz` file using `tar`
5. Generate `.sha256` checksum file
6. Verify checksum integrity
7. Clean up old backups using retention rules
8. Log everything in `backup.log`

---


###  **Backup Rotation Algorithm (How Old Backups Are Deleted)**

The backup rotation system ensures that only the **most recent backups** are kept, and older ones are deleted automatically to save disk space.

####  **Logic Behind It:**

1. The script looks at **all backup files** in the backup folder (`backup-*.tar.gz`).
2. It separates them into three categories based on age:

   * **Daily backups:** Newest backups from the last few days.
   * **Weekly backups:** One backup from each of the last few weeks.
   * **Monthly backups:** One backup from each of the last few months.
3. It keeps a limited number of backups in each category — defined in `backup.config`:

   ```bash
   DAILY_KEEP=7
   WEEKLY_KEEP=4
   MONTHLY_KEEP=3
   ```
4. Backups older than these limits are **deleted automatically**.


```bash
find . -type f -name "backup-*.tar.gz" -mtime +28 -delete
```

This automatically removes backups older than 28 days, depending on your rotation policy.

---

###  **Checksum Creation and Verification**

Checksums are used to verify the **integrity** of each backup — ensuring it wasn’t corrupted or changed after creation.

####  **How It Works:**

1. After each backup is created, the script generates a **SHA256 checksum** file:

   ```bash
   sha256sum "$BACKUP_DESTINATION/$backup_name" > "$BACKUP_DESTINATION/$checksum_file"
   ```

   This creates a text file (for example `backup-2025-11-04-0910.tar.gz.sha256`) containing a unique hash signature for that backup.

2. To verify integrity, it compares the backup’s current hash to the stored one:

   ```bash
   sha256sum -c "$1.sha256"
   ```

3. If the two hashes match →  the backup is valid.
   If they don’t →  the backup is considered corrupted or modified.

####  **Example Log**

```
[2025-11-04 09:10:33] INFO: Checksum verified successfully
[2025-11-04 09:10:40] ERROR: Backup verification failed (checksum mismatch)
```


---


















### **Folder Structure**

```
backup/
├── backup.sh                # Main backup script
├── backup.config            # Configuration file (settings & exclusions)
├── backup.log               # Log file storing all actions and errors
├── email.txt                # Simulated email notifications
├── restore/                 # Folder where backups can be restored
├── backupfiles/             # Destination folder where backups are stored
│    ├── backup-2025-11-04-0857.tar.gz          # Compressed backup
│    ├── backup-2025-11-04-0857.tar.gz.sha256   # Checksum file for verification
│    ├── backup.snar                            # Snapshot file for incremental backups
│
└── /mnt/c/Users/hp/Documents/files/             # SOURCE folder (contains files to be backed up)
     ├── a.txt
     ├── b.txt
     ├── notes.txt



```

---

##  **Testing**

## **Test Cases Performed**

1. **Create Backup** – Ran the script normally with a valid folder.
    **Result**: Backup created successfully.

2. **Dry Run** – Executed with dry-run option.
    **Result**: Logs generated without creating backup files.

3. **Disk Check** – Tested with low disk space.
    **Result**: Error message “Not enough disk space” shown, safe exit.

4. **Restore** – Tested restore feature with `.tar.gz` backup.
    **Result**: Files restored correctly.

5. **Old Backup Cleanup** – Simulated old backups (7–30 days).
    **Result**: Deleted old backups per rotation policy.

6. **Invalid Folder** – Tried backing up non-existent folder.
    **Result**: Proper error message shown, script didn’t crash.

**Sample Output:**

```
[2025-11-04 08:57:53] INFO: Starting backup of /mnt/c/Users/hp/Documents/files
[2025-11-04 08:57:54] SUCCESS: Backup created: backup-2025-11-04-0857.tar.gz
[2025-11-04 08:57:54] INFO: Checksum verified successfully
[2025-11-04 08:57:54] Email simulated: Backup Success
[2025-11-04 08:57:54] Cleaning old backups...
```

---

##  **Approach**

Used a **modular Bash script** with separate functions for each operation (`create_backup`, `verify_backup`, `delete_old_backups`, `restore_backup`).
The configuration file makes values flexible and avoids hardcoding.

---

##  **Challenges Faced**

* Managing multiple backup types (daily, weekly, monthly)
* Verifying backup integrity
* Handling low space and missing paths gracefully

---

##  **Solutions Implemented**

*  Added **checksum verification** for data integrity
*  Used **lock file mechanism** to prevent multiple runs
*  Implemented detailed **logging** in `backup.log`
*  Created a **config system** for flexible path management



##  **Limitations**

* No real email sending (simulated via `email.txt`)
* CLI-based only — no GUI or web dashboard
* Restore assumes `.tar.gz` file exists (no partial file checks)
* No remote/cloud backup yet

---

##  **Future Improvements**

* Add **real email notifications** via SMTP
* Implement **cloud backup** (AWS S3 / Google Drive)
* Add **encryption** for secure backups
* Schedule automated runs via **cron jobs**

---

##  **Conclusion**

This project automates the **entire backup lifecycle** — from creation to verification, rotation, and restoration — using pure Bash scripting.
It demonstrates a strong understanding of **Linux commands**, **automation logic**, **error handling**, and **data protection principles**.
