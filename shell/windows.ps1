# Notes vault path (edit to your clone path in Windows)
if (-not (Get-Item env:NOTES_DIR -ErrorAction SilentlyContinue)) {
  [Environment]::SetEnvironmentVariable("NOTES_DIR", "$HOME\notes", "User")
}
$env:EDITOR = "nvim"
