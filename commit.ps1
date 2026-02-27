cd C:\meldrino_app
git add .
$message = Read-Host "Enter commit message"
git commit -m $message
git push origin main
Write-Host "Done! Changes pushed to GitHub." -ForegroundColor Green