$Path = 'C:\TEMP\BPA\M365Inspect'
$OutPath = 'C:\TEMP\BPA\M365Inspect\Output'
$Username = 'victor@nubrixsecurity.com'
if (Test-Path -Path $Path) {
	Remove-Item $Path -Recurse -Force
	New-Item $Path -Type Directory
	git clone https://github.com/soteria-security/365Inspect $Path
	cd $Path
	.\365Inspect.ps1 -OutPath $OutPath -UserPrincipalName $Username -Auth MFA
}
else {
	New-Item $Path -Type Directory
	git clone https://github.com/soteria-security/365Inspect $Path
	cd $Path
	.\365Inspect.ps1 -OutPath $OutPath -UserPrincipalName $Username -Auth MFA
}