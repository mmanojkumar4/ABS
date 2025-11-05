
#  **Backup System Testing Guide**

This document demonstrates how to test all the major features of the `backup.sh` script — including backup creation, incremental backups, cleanup, restore, and error handling.


---

## 1️ **Creating a Backup**

**Command:**

```bash
./backup.sh /mnt/c/Users/hp/Documents/files
```

**Description:**
This creates a **compressed `.tar.gz` backup** of your selected folder inside the backup destination.
It also generates a `.sha256` checksum file for verification.

**Result Screenshot:**
![Backup](https://github.com/mmanojkumar4/Automatic_Backup_System/blob/b59204ce2aa860fecfd17f7fe95262068e8dec9d/test_folder/backup.png)

---

## 2️ **Creating Multiple Backups Over “Days”**

**Command:**

```bash
touch -d "7 days ago" backup-2025-11-04-1010.tar.gz
touch -d "14 days ago" backup-2025-11-04-1030.tar.gz
touch -d "1 month ago" backup-2025-11-04-1050.tar.gz
```

**Description:**
Simulates multiple backups taken over different dates.
The system performs **incremental backups** automatically if a `.snar` file exists.

**Result Screenshots:**

 Multiple file creation
![Multiple Files](https://github.com/mmanojkumar4/Automatic_Backup_System/blob/b59204ce2aa860fecfd17f7fe95262068e8dec9d/test_folder/files_creation_duplicate_date.png)

 Incremental backup
![Incremental Backup](https://github.com/mmanojkumar4/Automatic_Backup_System/blob/b59204ce2aa860fecfd17f7fe95262068e8dec9d/test_folder/incremental_backup.png)

---

## 3️ **Automatic Deletion of Old Backups**

**Command:**

```bash
./backup.sh /mnt/c/Users/hp/Documents/files
```

**Description:**
After creating a new backup, the script automatically deletes old ones beyond the **daily, weekly, and monthly limits** defined in `backup.config`.

**Result Screenshot:**
 Old backups removed successfully
![Automatic Deletion](https://github.com/mmanojkumar4/Automatic_Backup_System/blob/b59204ce2aa860fecfd17f7fe95262068e8dec9d/test_folder/delete.png)

---

## 4️ **Restoring From a Backup**

**Command:**

```bash
./backup.sh --restore backup-2025-11-04-0909.tar.gz /mnt/c/Users/hp/Desktop/backup/restore
```

**Description:**
Restores all files from a `.tar.gz` backup into the given directory path.

**Result Screenshot:**
 Backup successfully restored
![Restore](https://github.com/mmanojkumar4/Automatic_Backup_System/blob/b59204ce2aa860fecfd17f7fe95262068e8dec9d/test_folder/restore.png)

---

## 5️ **Dry Run Mode**

**Command:**

```bash
./backup.sh --dry-run /mnt/c/Users/hp/Documents/files
```

**Description:**
Simulates the backup process **without actually creating files**.
Used to test whether all configurations and exclusions are working properly.

**Result Screenshot:**
 Dry run successful
![Dry Run](https://github.com/mmanojkumar4/Automatic_Backup_System/blob/b59204ce2aa860fecfd17f7fe95262068e8dec9d/test_folder/dryrun.png)

---

## 6️ **Email Notification (Simulated)**

**Description:**
After each backup (or error), the system writes simulated email alerts to a file named `email.txt`.

Example simulated output:

```text
Subject: Backup Success
Backup /mnt/c/Users/hp/Documents/files verified successfully.
```

**Result Screenshot:**
 Simulated email created
![Email](https://github.com/mmanojkumar4/Automatic_Backup_System/blob/b59204ce2aa860fecfd17f7fe95262068e8dec9d/test_folder/email.png)

---

## 7️ **Error Handling Test**

**Command:**

```bash
./backup.sh /mnt/c/Users/hp/Documents/wrongpath
```

**Description:**
Tests the script’s ability to handle **invalid or missing folders**.
The script safely logs and displays the error instead of crashing.

**Expected Output:**

```bash
Source directory not found: /mnt/c/Users/hp/Documents/wrongpath
```

**Result Screenshot:**
 Proper error message displayed
![Error Handling](https://github.com/mmanojkumar4/Automatic_Backup_System/blob/b59204ce2aa860fecfd17f7fe95262068e8dec9d/test_folder/folder_error.png)

---

## 8️ **Listing Available Backups**

**Command:**

```bash
./backup.sh --list
```

**Description:**
Lists all available backup archives with file sizes and timestamps.
Helps quickly review backup history.

**Result Screenshot:**
 Backups listed successfully
![List](https://github.com/mmanojkumar4/Automatic_Backup_System/blob/b59204ce2aa860fecfd17f7fe95262068e8dec9d/test_folder/list.png)

---

##  **Summary**

| Test               | Description                                    | Result |
| ------------------ | ---------------------------------------------- | ------ |
| Backup Creation    | Full backup created successfully               |  Pass |
| Incremental Backup | Detected and backed up only changed files      |  Pass |
| Old Backup Cleanup | Older archives deleted as per retention policy |  Pass |
| Restore Function   | Files restored to target directory             |  Pass |
| Dry Run Mode       | Simulated backup without creating files        |  Pass |
| Email Log          | Backup notifications simulated                 |  Pass |
| Error Handling     | Invalid folder handled safely                  |  Pass |
| List Backups       | All backups listed properly                    |  Pass |

