#!/bin/bash
# filepath: scripts/backup_hdd.sh

set -e

# Configuration
SOURCE_DIR="/mnt/hdd"
BACKUP_BASE_DIR="/mnt/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$BACKUP_BASE_DIR/hdd_backup_$TIMESTAMP"
LATEST_LINK="$BACKUP_BASE_DIR/hdd_latest"
IGNORE_FILE="$(dirname "$0")/hdd_ignore.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if source exists
if [ ! -d "$SOURCE_DIR" ]; then
    error "Source directory $SOURCE_DIR does not exist!"
fi

# Create ignore file if it doesn't exist
if [ ! -f "$IGNORE_FILE" ]; then
    log "Creating ignore file: $IGNORE_FILE"
    cat > "$IGNORE_FILE" << 'EOF'
ignore/
p-stream/
# System and temporary files
.DS_Store
Thumbs.db
.tmp
*.tmp
*.temp
.cache/
tmp/
temp/

# Docker related
**/overlay2/
**/containers/storage/
**/docker/tmp/

# Database files that might be locked
*.db-wal
*.db-shm

# Large media cache files
**/.thumbnails/
**/cache/
**/.cache/

# Log files (optional - remove if you want logs)
*.log
**logs/
**/log/

# Backup files
*.bak
*.backup
*~

# System directories
proc/
sys/
dev/
run/
lost+found/

# Homelab service-specific excludes based on your services.yaml
**/jellyfin/cache/
**/jellyfin/log/
**/jellyfin/transcodes/
**/portainer/docker_endpoints/
**/roundcube/temp/
**/roundcube/logs/
**/adguardhome/data/querylog.json*
**/adguardhome/data/stats.db*
**/vaultwarden/tmp/
**/searxng/cache/

# Socket files and pipes
*.sock
*.socket
ipc-socket

# Minecraft server logs (if present)
**/minecraft/logs/
**/minecraft/crash-reports/

EOF
    warn "Created default ignore file. Please review and modify $IGNORE_FILE as needed."
fi

# Create backup directory
log "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Display backup info
info "Backup Configuration:"
info "  Source: $SOURCE_DIR"
info "  Destination: $BACKUP_DIR"
info "  Ignore file: $IGNORE_FILE"
info "  Timestamp: $TIMESTAMP"

# Calculate source size (excluding ignored files)
log "Calculating source size..."
SOURCE_SIZE=$(du -sh "$SOURCE_DIR" 2>/dev/null | cut -f1)
info "Source directory size: $SOURCE_SIZE"

# Show ignore patterns being used
info "Using ignore patterns:"
cat "$IGNORE_FILE" | grep -v '^#' | grep -v '^$' | sed 's/^/  - /'

# Confirm backup
echo
read -p "Proceed with backup? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    warn "Backup cancelled."
    exit 0
fi

# Start backup
log "Starting HDD backup..."
START_TIME=$(date +%s)

# Run rsync with progress and exclude file
rsync -ruv \
    --progress \
    --stats \
    --human-readable \
    --exclude-from="$IGNORE_FILE" \
    --log-file="$BACKUP_DIR/rsync.log" \
    "$SOURCE_DIR/" \
    "$BACKUP_DIR/data/" || warn "Rsync completed with warnings (check log)"

# Calculate backup time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
HOURS=$((DURATION / 3600))
MINUTES=$(((DURATION % 3600) / 60))
SECONDS=$((DURATION % 60))

# Get backup size
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

# Create backup metadata
log "Creating backup metadata..."
cat > "$BACKUP_DIR/backup_info.txt" << EOF
HDD Backup Information
=====================

Backup Date: $(date)
Source: $SOURCE_DIR
Backup Size: $BACKUP_SIZE
Source Size: $SOURCE_SIZE
Duration: ${HOURS}h ${MINUTES}m ${SECONDS}s
Ignore File: $IGNORE_FILE

Backup Location: $BACKUP_DIR

Restore Command:
rsync -ruv --progress "$BACKUP_DIR/data/" "$SOURCE_DIR/"

Note: Review the restore command carefully before executing!
EOF

# Copy ignore file to backup for reference
cp "$IGNORE_FILE" "$BACKUP_DIR/ignore_patterns.txt"

# Update latest symlink
log "Updating latest backup link..."
rm -f "$LATEST_LINK"
ln -sf "$(basename "$BACKUP_DIR")" "$LATEST_LINK"

# Create verification script
cat > "$BACKUP_DIR/verify_backup.sh" << 'EOF'
#!/bin/bash
# Verify backup integrity

BACKUP_DIR=$(dirname "$0")
SOURCE_DIR="/mnt/hdd"

echo "Verifying backup integrity..."
echo "Comparing file counts and sizes..."

# Compare directory structure
echo "Checking directory structure..."
diff <(find "$SOURCE_DIR" -type d | sort) <(find "$BACKUP_DIR/data" -type d | sort) || echo "Directory differences found"

# Compare file counts
SOURCE_COUNT=$(find "$SOURCE_DIR" -type f | wc -l)
BACKUP_COUNT=$(find "$BACKUP_DIR/data" -type f | wc -l)

echo "Source files: $SOURCE_COUNT"
echo "Backup files: $BACKUP_COUNT"

if [ "$SOURCE_COUNT" -eq "$BACKUP_COUNT" ]; then
    echo "✅ File counts match"
else
    echo "⚠️  File count mismatch"
fi

echo "Verification complete. Check output above for any issues."
EOF

chmod +x "$BACKUP_DIR/verify_backup.sh"

# Cleanup old backups (keep last 3 HDD backups)
log "Cleaning up old backups..."
find "$BACKUP_BASE_DIR" -maxdepth 1 -name "hdd_backup_*" -type d | sort -r | tail -n +4 | xargs rm -rf 2>/dev/null || true

# Final summary
log "Backup completed successfully!"
info "Backup Summary:"
info "  Location: $BACKUP_DIR"
info "  Size: $BACKUP_SIZE"
info "  Duration: ${HOURS}h ${MINUTES}m ${SECONDS}s"
info "  Latest link: $LATEST_LINK"
info "  Log file: $BACKUP_DIR/rsync.log"
info "  Verify script: $BACKUP_DIR/verify_backup.sh"

# Show disk usage
BACKUP_DISK_USAGE=$(df -h "$BACKUP_BASE_DIR" | tail -1 | awk '{print $5 " used (" $4 " free)"}')
info "Backup disk usage: $BACKUP_DISK_USAGE"

echo
echo "To restore: rsync -ruv --progress '$BACKUP_DIR/data/' '$SOURCE_DIR/'"
echo "To verify: $BACKUP_DIR/verify_backup.sh"