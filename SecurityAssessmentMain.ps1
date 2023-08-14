#START BPA - CHECK IF MODULES EXISTS
$Modules = @('ExchangeOnlineManagement',`
			 'PowerShellGet',`
			 'Microsoft.Online.SharePoint.PowerShell',`
			 'Microsoft.Graph',`
			 'MicrosoftTeams')
			 
foreach($m in $Modules)	{
	if (Get-Module | Where-Object {$_.Name -eq $m}) {
		write-host "Module already imported: $m" -Foreground CYAN
	}
	else {
		# If module is not imported, but available on disk then import
		if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $m}) {
			write-host "Importing module: $m" -Foreground CYAN
			Import-Module $m
		}
		else {
			write-host "Installing module: $m" -Foreground CYAN
			Install-Module -Name $m -Scope CurrentUser -AllowClobber -Force -SkipPublisherCheck
			Import-Module -Name $m 
		}
	}
}

#DOWNLOAD GITHUB REPOSITORY
$Path = 'C:\TEMP\BPA\'
if (Test-Path -Path $Path) {
	Remove-Item $Path -Recurse -Force
	New-Item $Path -Type Directory
	git clone https://github.com/nubrixsecurity/bpa $Path
}
else {
	New-Item $Path -Type Directory
	git clone https://github.com/nubrixsecurity/bpa $Path
}

#RUN SECURITY ASSESSMENTS
cd $Path
Write-Host "Running script: M365 Inspect" -Foreground green
.\M365Inspect.ps1

cd $Path
Write-Host "Running script: Microsoft Compliance Configuration Analyzer" -Foreground green
.\MCCA.ps1

cd $Path
Write-Host "Running script: Microsoft Defender for Office 365" -Foreground green
.\ORCA.ps1	