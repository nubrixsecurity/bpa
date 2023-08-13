<#

#CHECK IF MODULES EXISTS
$Modules = @('ExchangeOnlineManagement',`
			 'Microsoft.Online.SharePoint.PowerShell',`
			 'Microsoft.Graph',`
			 'MicrosoftTeams')

# If module is imported say that and do nothing
foreach($m in $Modules)	{
	if (Get-Module | Where-Object {$_.Name -eq $m}) {
		write-host "Module already imported: $m" -Foreground CYAN
	}
	else {
		# If module is not imported, but available on disk then import
		if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $m}) {
			write-host "Importing module: $m" -Foreground CYAN
			Import-Module $m
			Install-Module -Name PowerShellGet -AllowPrerelease -AllowClobber -Force 
		}
		else {
			write-host "Installing module: $m" -Foreground CYAN
			Install-Module -Name $m -Scope CurrentUser -AllowClobber -Force -SkipPublisherCheck
			Install-Module -Name PowerShellGet -AllowPrerelease -AllowClobber -Force 
			Import-Module -Name $m 
		}
	}
}
#>

$Path = 'C:\TEMP\BPA\M365Inspect'
$OutPath = 'C:\TEMP\BPA\M365Inspect\Output'
$Username = 'victor@nubrixsecurity.com'
if (Test-Path -Path $Path) {
	Remove-Item $Path -Recurse -Force
	New-Item $Path -Type Directory
	New-Item $OutPath -Type Directory
	git clone https://github.com/soteria-security/365Inspect $Path
	Copy-Item 'C:\TEMP\BPA\365Inspect.ps1' -Destination "C:\TEMP\BPA\M365Inspect\"
	cd $Path
	.\365Inspect.ps1 -OutPath $OutPath -UserPrincipalName $Username -Auth MFA
}
else {
	New-Item $Path -Type Directory
	New-Item $OutPath -Type Directory
	git clone https://github.com/soteria-security/365Inspect $Path
	Copy-Item 'C:\TEMP\BPA\365Inspect.ps1' -Destination "C:\TEMP\BPA\M365Inspect\"
	cd $Path
	.\365Inspect.ps1 -OutPath $OutPath -UserPrincipalName $Username -Auth MFA
}

