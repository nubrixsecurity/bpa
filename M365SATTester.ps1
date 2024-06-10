#Requires -Version 5.1
#Requires -RunAsAdministrator

param ($outPath)
<#
Connect-MgGraph
$userPrincipalName = (Get-MgContext).account
$tenantId = (Get-MgContext).TenantId
$domain = (Get-MgSubscribedSku | select -First 1).accountname
$url = 'https://'+$domain+'-admin.sharepoint.com'
#>
Connect-AzAccount
$userPrincipalName = (Get-AzAccessToken).userid
$fullDomain = (Get-AzTenant).DefaultDomain
$domain = ($fullDomain -split ".c")[0]
$url = 'https://'+$domain+'-admin.sharepoint.com'

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
<#
Connect-MgGraph
Connect-ExchangeOnline
Connect-IPPSSession
Connect-SPOService -Url $url
Connect-MicrosoftTeams
#>
function ExecuteM365SAT
{
	Import-Module .\M365SAT.psd1

	Get-M365SATReport `
		-OutPath $outPath `
		-Username $userPrincipalName `
		-reportType "HTML" `
		-AllowLogging "Warning" `
		-Modules All `
		-BenchmarkVersion LATEST `
		-LicenseMode All `
		-LicenseLevel All `
		-EnvironmentType AZURE,M365 `
  		-SkipChecks
		
	Remove-Module M365SAT -Force
}


function CheckAdminPrivBeta
{
	# Check if script is running as Adminstrator and if not use RunAs
	Write-Host "[...] Checking if the script is running as Administrator"
	$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
	if (-not $IsAdmin)
	{
		Write-Warning "[!] Program needs Administrator Rights! Trying to Elevate to Admin..."
		Start-Process powershell -Verb runas -ArgumentList "-NoExit -c cd '$pwd'; .\M365SATTester.ps1"
	}
	else
	{
		Write-Host "[+] The script is running as Administrator..." -ForegroundColor Green
		ExecuteM365SAT
	}
}
CheckAdminPrivBeta
