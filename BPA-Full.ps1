#RUN SCRIPT ON POWERSHELL 7.3.6

#GET REPO FILES
$Path = 'C:\TEMP\BPA'

if (Test-Path -Path $Path) {
	Remove-Item $Path -Recurse -Force
	New-Item $Path -Type Directory
	git clone https://github.com/nubrixsecurity/bpa $Path
}
else {
	New-Item $Path -Type Directory
	git clone https://github.com/nubrixsecurity/bpa $Path
}

#DEFINE VARIABLES
$UserPrincipalName = Read-Host -Prompt 'Input User Name'
<#
#START BPA - CHECK IF MODULES EXISTS
$Modules = @('PowerShellGet', 'ExchangeOnlineManagement', 'MCCAPreview', 'ORCA')

$MaximumFunctionCount = 32768

foreach($m in $Modules)	{
	if (Get-Module | Where-Object {$_.Name -eq $m}) {
		write-host "Module already imported: $m" -Foreground green
	}
	else {
		if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $m}) {
			if($m -eq 'PowerShellGet'){
				try{
					write-host "Importing module: $m" -Foreground green
					Import-Module -Name $m
					Update-Module -Name $m -Force
				}
				catch{
					write-host "Installing module: $m" -Foreground green
					Install-Module -Name $m -Scope CurrentUser -AllowClobber -Force
					Import-Module -Name $m
					Update-Module -Name $m -Force
				}				 			 
			}
			else
			{
				write-host "Importing module: $m" -Foreground green
				Import-Module $m
			}
			
		}
		else {
			write-host "Installing module: $m" -Foreground green
			Install-Module -Name $m -Scope CurrentUser -AllowClobber -Force
			Import-Module -Name $m 
		}
	}
}
#>

#CHECK IF MODULES EXISTS
$Modules = @('Az',`
			 'PowerShellGet',`
			 'ExchangeOnlineManagement',`
			 'Microsoft.Online.SharePoint.PowerShell',`
			 'Microsoft.Graph',`
			 'MicrosoftTeams',`
			 'MCCAPreview',
			 'ORCA',
			 'PoShLog',`
			 'posh-git')

$MaximumFunctionCount = 32768

foreach($m in $Modules){
	# If module is imported say that and do nothing
	if (Get-Module | Where-Object {$_.Name -eq $m}) {
		write-host "Module already imported: $m" -Foreground green
	}
	else {
		# If module is not imported, but available on disk then import
		if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $m}) {
			write-host "Importing module: $m" -Foreground green
			Import-Module $m
		}
		else {
			if($m -eq 'Az'){
				try{
					write-host "Importing module: $m" -Foreground green
					Import-Module -Name $m
				}
				catch{
					write-host "Installing module: $m" -Foreground green
					Install-Module -Name $m -Scope CurrentUser -AllowClobber -Force
					Import-Module -Name $m
				}				 			 
			}
			else{
				write-host "Installing module: $m" -Foreground green
				Install-Module -Name $m -Scope CurrentUser -Force -SkipPublisherCheck
				Import-Module -Name $m 
			}
		}
	}
}

#CONNECT TO EXCHANGEONLINE
$getsessions = Get-ConnectionInformation | Select-Object -Property State, Name
$isconnected = (@($getsessions) -like '@{State=Connected; Name=ExchangeOnline*').Count -gt 0

If ($isconnected -ne "True") {
	Try {
		Write-Host "Connecting to ExchangeOnline." -Foreground green
		Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -ShowBanner:$false
	}
	Catch {
		Write-Host "Connecting to ExchangeOnline Failed." -Foreground RED
		Write-Error $_.Exception.Message
		Break
	}
}
else{
	Write-Host "ExchangeOnline Connected." -Foreground green
}
	
#MCCA ASSESSMENT
Write-Host "RUNNING MCCA ASSESSMENT." -Foreground CYAN
Get-MCCAReport
cd 'C:\Users\*\AppData\Local\Microsoft\MCCA\'
ii .

#MDO ASSESSMENT
Write-Host "RUNNING ORCA ASSESSMENT." -Foreground CYAN
Get-ORCAReport	
cd 'C:\Users\*\AppData\Local\Microsoft\ORCA\'
ii .

#M365INSPECT ASSESSMENT
Write-Host "RUNNING M365INSPECT ASSESSMENT." -Foreground CYAN
$Path = 'C:\TEMP\BPA\M365Inspect'
$OutPath = 'C:\TEMP\BPA\M365Inspect\Output'

if (Test-Path -Path $Path) {
	Remove-Item $Path -Recurse -Force
	New-Item $Path -Type Directory
	git clone https://github.com/soteria-security/365Inspect $Path
	cd $Path
	.\365Inspect.ps1 -OutPath $OutPath -UserPrincipalName $UserPrincipalName -Auth MFA
}
else {
	New-Item $Path -Type Directory
	git clone https://github.com/soteria-security/365Inspect $Path
	cd $Path
	.\365Inspect.ps1 -OutPath $OutPath -UserPrincipalName $UserPrincipalName -Auth MFA
}

#M365SAT ASSESSMENT
Write-Host "RUNNING M365SAT ASSESSMENT." -Foreground CYAN
$Path = 'C:\TEMP\BPA\M365SAT'

if (Test-Path -Path $Path) {
	Remove-Item $Path -Recurse -Force
	New-Item $Path -Type Directory
	git clone https://github.com/asterictnl-lvdw/M365SAT $Path
	Copy-Item 'C:\TEMP\BPA\M365SATTester.ps1' -Destination $Path
	cd $Path 
	.\M365SATTester.ps1 $UserPrincipalName
}
else {
	New-Item $Path -Type Directory
	git clone https://github.com/asterictnl-lvdw/M365SAT $Path
	Copy-Item 'C:\TEMP\BPA\M365SATTester.ps1' -Destination $Path
	cd $Path 
	.\M365SATTester.ps1 $UserPrincipalName
}