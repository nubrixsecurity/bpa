#RUN SCRIPT ON POWERSHELL 7.3.6

$ErrorActionPreference = 'silentlycontinue'

Write-Host '---- CHECKING IF GIT IS INSTALLED ----' -f CYAN

#INSTALL GIT WINGET
$gitInstalled = git --version
if($gitInstalled -eq $null){
    write-host "Installing Git" -Foreground yellow
    winget install --id Git.Git -e --source winget
}
else{write-host "Git already installed" -Foreground green}

#INPUT VARIABLES
$inputOrg = $(Write-Host "Input Organization Name: " -f yellow -NoNewLine; Read-Host)
$tenantId = $(Write-Host "Input Tenant Id: " -f yellow -NoNewLine; Read-Host)

#CREATE DIRECTORY FOLDERS
$path = 'C:\BPA'
$getDate = Get-Date -Format 'MM/dd/yyyy'
$date = $getDate -replace '/','.'
$pathDate = $path+'-'+$date
$gitHubPath = 'GitHubRepo'
$orgName = $inputOrg.ToUpper()

if ($pathDate -notlike '*\'){$mainPath = $pathDate + "\"}

$clonePathC1 = $mainPath+$gitHubPath+'\C1\'
$clonePathM365SAT = $mainPath+$gitHubPath+'\M365SAT\'
$outPath = $mainPath+$orgName+'\Report\'

Write-Host '---- CREATING DIRECTORY FOLDERS ----' -f CYAN

if (Test-Path -Path $clonePathC1) {
	Remove-Item $clonePathC1 -Recurse -Force
	New-Item $clonePathC1 -Type Directory
	git clone https://github.com/nubrixsecurity/bpa $clonePathC1
}
else {
	New-Item $clonePathC1 -Type Directory
	git clone https://github.com/nubrixsecurity/bpa $clonePathC1
}

if (Test-Path -Path $clonePathM365SAT) {
	Remove-Item $clonePathM365SAT -Recurse -Force
	New-Item $clonePathM365SAT -Type Directory
	git clone https://github.com/asterictnl-lvdw/M365SAT $clonePathM365SAT
}
else {
	New-Item $clonePathM365SAT -Type Directory
	git clone https://github.com/asterictnl-lvdw/M365SAT $clonePathM365SAT
}

$ErrorActionPreference = 'stop'

#UNBLOCK FILES
$files = Get-ChildItem $pathDate -Recurse -File

foreach ($file in $files) {
    Unblock-File -Path $file.FullName -Confirm:$false
}

#CHECK IF MODULES EXISTS
Write-Host '---- CHECKING MODULES ----' -f CYAN

$Modules = @('Az',`
			 'ExchangeOnlineManagement',`
			 'Microsoft.Online.SharePoint.PowerShell',`
			 'Microsoft.Graph',`
			 'MicrosoftTeams',`
			 'PoShLog')

foreach($m in $Modules){
	if($m -eq 'Az'){
		$name = 'Az*'
		$module = Get-Module -ListAvailable | where-Object {$_.Name -like $name} | select name
			
		if($module.name -ne $null){
			write-host "Module already installed: $m" -Foreground green
		}
		else{
			write-host "Installing module: $m" -Foreground yellow
			Install-Module -Name $m -Scope CurrentUser -Force -AllowClobber
			#Import-Module -Name $m 
		}
	}
	else{
		$module = Get-Module -Name $m -ListAvailable | select name
			
		if($module.name -ne $null){
			write-host "Module already installed: $m" -Foreground green
		}
		else{
			write-host "Installing module: $m" -Foreground yellow
			Install-Module -Name $m -Scope CurrentUser -Force -AllowClobber
			#Import-Module -Name $m 
		}
	}
}

#M365SAT ASSESSMENT
Write-Host '---- RUNNING M365SAT ASSESSMENT ----' -f CYAN

$copyFile = $clonePathC1+'M365SATTester.ps1'
Copy-Item $copyFile -Destination $clonePathM365SAT

cd $clonePathM365SAT
.\M365SAT-Start.ps1 $tenantId $outPath
