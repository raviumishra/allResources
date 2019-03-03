param(
[string]$uri
)
Invoke-RestMethod -Method POST -Uri $uri
Start-Sleep 30
shutdown /r
