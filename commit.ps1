cd C:\meldrino_app
git add .
$message = Read-Host "Enter commit message"
if ([string]::IsNullOrWhiteSpace($message)) {
    Write-Host "Commit message cannot be empty. Aborting." -ForegroundColor Red
    exit
}
git commit -m $message
git pull origin main --rebase
git push origin main
Write-Host "Done! Changes pushed to GitHub." -ForegroundColor Green
