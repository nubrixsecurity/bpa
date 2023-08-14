<#$MaximumFunctionCount = 32768

#START BPA - CHECK IF MODULES EXISTS
$Modules = @('ExchangeOnlineManagement',`
			 'Microsoft.Online.SharePoint.PowerShell',`
			 'Microsoft.Graph',`
			 'MicrosoftTeams')
			 
foreach($m in $Modules)	{
	if (Get-Module | Where-Object {$_.Name -eq $m}) {
		write-host "Module already imported: $m" -Foreground CYAN
	}
	else {
		if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $m}) {
			write-host "Importing module: $m" -Foreground CYAN
			Import-Module -Name $m
			Update-Module -Name $m -Force		
		}
		else {
			write-host "Installing module: $m" -Foreground CYAN
			Install-Module -Name $m -Scope CurrentUser -AllowClobber -Force -SkipPublisherCheck
			Import-Module -Name $m 
			Update-Module -Name $m -Force	
		}
	}
}#>

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