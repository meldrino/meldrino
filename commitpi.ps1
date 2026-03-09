# commitpi.ps1 - Backup Pi website files to local folder then push to GitHub

$piUser = "andy"
$piHost = "192.168.1.100"
$backupDir = "C:\meldrino_app\pi_backup"

# Create backup directories if they don't exist
New-Item -ItemType Directory -Force -Path "$backupDir\html" | Out-Null
New-Item -ItemType Directory -Force -Path "$backupDir\zbd_connect\public" | Out-Null

Write-Host "Backing up Pi files..."

# Backup /var/www/html/ (icons + HTML files)
scp -r "${piUser}@${piHost}:/var/www/html/*" "$backupDir\html\"

# Backup ZBD connect files
scp "${piUser}@${piHost}:/home/andy/meldrino-zbd-connect/server.js" "$backupDir\zbd_connect\"
scp "${piUser}@${piHost}:/home/andy/meldrino-zbd-connect/package.json" "$backupDir\zbd_connect\"
scp "${piUser}@${piHost}:/home/andy/meldrino-zbd-connect/package-lock.json" "$backupDir\zbd_connect\"
scp "${piUser}@${piHost}:/home/andy/meldrino-zbd-connect/public/index.html" "$backupDir\zbd_connect\public\"

Write-Host "Backup complete. Pushing to GitHub..."

# Commit and push to GitHub
cd C:\meldrino_app
git config core.autocrlf false
git add .
$msg = Read-Host "Enter commit message"
git commit -m $msg
git push

Write-Host "Done! Pi backup pushed to GitHub."
