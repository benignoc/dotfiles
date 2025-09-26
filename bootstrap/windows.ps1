# Run in PowerShell (non-admin)
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force

# Package managers & tools
winget install -e --id Git.Git
winget install -e --id Neovim.Neovim
winget install -e --id BurntSushi.ripgrep
winget install -e --id sharkdp.fd
winget install -e --id Microsoft.PowerShell
winget install -e --id JesseDuffield.lazygit
winget install -e --id NodeJS.NodeJS

# Create nvim config
$dst = "$env:LOCALAPPDATA\nvim"
New-Item -ItemType Directory $dst -Force | Out-Null
robocopy "$(Get-Location)\nvim" $dst /E /NFL /NDL /NJH /NJS /NC | Out-Null

# PowerShell profile
if (!(Test-Path -Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
Get-Content "$(Get-Location)\shell\windows.ps1" | Add-Content -Path $PROFILE

Write-Host "Done. Restart PowerShell. Set NOTES_DIR to your notes repo path."
