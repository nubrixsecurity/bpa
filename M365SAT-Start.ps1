param ($outPath,$userPrincipalName)

$ErrorActionPreference = 'silentlycontinue'

Write-Host '---- CHECKING MODULES ----' -f CYAN

<#INSTALL GIT WINGET
$gitInstalled = git --version
if($gitInstalled -eq $null){
    write-host "Installing Git" -Foreground yellow
    winget install --id Git.Git -e --source winget
}
else{write-host "Module already installed: Git" -Foreground green}

#CHECK IF MODULES EXISTS
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
}#>

$ErrorActionPreference = 'stop'

#M365SAT ASSESSMENT
Write-Host '---- RUNNING M365SAT ASSESSMENT ----' -f CYAN

<#
Connect-MgGraph
$tenantId = (Get-MgContext).TenantId
$userPrincipalName = (Get-MgContext).account

$subs = Get-AzSubscription | Select-Object name

# Enumerate items with numbers for selection
$choices = @{}
$count = 0
$num = 1

foreach ($i in $subs){
  $choices[$num] = $i.name
  Write-Host "$num. $($choices[$num])"  # Display option with number and name
  $count++
  $num++

}

# Get user input and validate
Write-Host ""
$message = "Choose the subscription you want to scan"
$choice = Read-Host $message
$choice = [int]$choice  

Write-Host "You selected: $($choices[$choice])" -f Green

#SET SUBSCRIPTION
Update-AzConfig -DefaultSubscriptionForLogin $choices[$choice] -WarningAction Ignore
#>

#RUN M365SAT
.\M365SATTester.ps1 $outPath $userPrincipalName

#OPEN THE HTML REPORT
$folder = Get-ChildItem -Path $outPath -Directory | Where-Object {$_.Name -match '\d+$'}
$reportPath = $outPath+$folder
$HTML = Get-ChildItem $reportPath -Filter "*.html"

Set-Location $reportPath
Start-Process $HTML
