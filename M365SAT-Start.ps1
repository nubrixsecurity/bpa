param($outPath)

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
		$name = 'Az.*'
		$module = Get-Module -ListAvailable | where-Object {($_.Name -like $name) -or ($_.Name -eq $m)} | select name
			
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

$UserPrincipalName = $(Write-Host "Input User Name: " -f yellow -NoNewLine; Read-Host)
$credential = Get-Credential -Credential $UserPrincipalName

Connect-AzAccount -Credential $credential -WarningAction Ignore

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

$subId = Get-AzSubscription -SubscriptionName $choices[$choice] | Select-Object id
Write-Host "You selected: $($choices[$choice])" -f Green

#SET SUBSCRIPTION
Set-AzContext -Subscription $subId.id

.\M365SATTester.ps1 $outPath $UserPrincipalName

#OPEN THE HTML REPORT
$folder = Get-ChildItem -Path $outPath -Directory | Where-Object {$_.Name -match '\d+$'}
$reportPath = $outPath+$folder
$HTML = Get-ChildItem $reportPath -Filter "*.html"

cd $reportPath
Start-Process $HTML
