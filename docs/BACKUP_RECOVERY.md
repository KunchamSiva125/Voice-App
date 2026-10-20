# Database Backup, Disaster Recovery & Data Safety Procedures

## 1. Overview & Data Retention Strategy

The tiffin hotel ledger is business-critical financial data. Losing records leads to customer disputes and unrecoverable revenue loss.
We implement a **three-tier safety strategy**:
1. **Cloud Replica Set**: MongoDB Atlas automatically replicates across 3 nodes.
2. **Weekly Cold Snapshot (mongodump)**: Automated binary dump stored off-site.
3. **One-Click CSV Backups**: The hotel owner can download complete customer balances and transaction histories as Excel-compatible CSV files directly from the Admin Portal.

---

## 2. Automated Binary Backup (mongodump)

Install the MongoDB Database Tools (`mongodump` and `mongorestore`).

### 2.1 Running a Full Database Backup
```bash
# On Linux / macOS / Git Bash
BACKUP_DIR="./backups/$(date +%Y-%m-%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

mongodump \
  --uri="mongodb+srv://<USERNAME>:<PASSWORD>@cluster0.mongodb.net/tiffin_ledger_db" \
  --gzip \
  --out="$BACKUP_DIR"

echo "Backup completed successfully to $BACKUP_DIR"
```

### 2.2 Scheduled Daily Cron (Optional Linux Server)
Add to `crontab -e`:
```cron
# Runs every night at 11:30 PM IST (18:00 UTC)
0 18 * * * /usr/local/bin/backup_tiffin_db.sh >> /var/log/tiffin_backup.log 2>&1
```

---

## 3. Disaster Recovery & Database Restoration

If the database is accidentally corrupted or an erroneous multi-document script is executed:

### 3.1 Restoring from Gzip Dump
```bash
mongorestore \
  --uri="mongodb+srv://<USERNAME>:<PASSWORD>@cluster0.mongodb.net/tiffin_ledger_db" \
  --gzip \
  --drop \
  --dir="./backups/2026-10-20_233000/tiffin_ledger_db"
```
> [!CAUTION]
> The `--drop` flag replaces existing collections with the backup snapshot. Always take a pre-restore snapshot before running this command.

---

## 4. Verification & Health Check Checklist

After restoring:
1. Verify user accounts:
   ```bash
   mongosh "<URI>" --eval "db.users.countDocuments()"
   ```
2. Verify customer counts:
   ```bash
   mongosh "<URI>" --eval "db.customers.countDocuments()"
   ```
3. Verify transaction ledger integrity:
   ```bash
   mongosh "<URI>" --eval "db.ledgerTransactions.aggregate([{ \$group: { _id: '\$type', count: { \$sum: 1 }, totalPaise: { \$sum: '\$amountPaise' } } }])"
   ```
4. Log into the React Admin Portal and verify that the Dashboard balances reconcile.
