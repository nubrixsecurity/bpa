#DEFINE VARIABLES
$UserPrincipalName = Read-Host -Prompt 'Input User Name'

#START BPA - CHECK IF MODULES EXISTS
$Modules = @('PowerShellGet', 'ExchangeOnlineManagement')

$MaximumFunctionCount = 32768

foreach($m in $Modules)	{
	if (Get-Module | Where-Object {$_.Name -eq $m}) {
		write-host "Module already imported: $m" -Foreground CYAN
	}
	else {
		if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $m}) {
			if($m -eq 'PowerShellGet'){
				try{
					write-host "Importing module: $m" -Foreground CYAN
					Import-Module -Name $m
					Update-Module -Name $m -Force
				}
				catch{
					write-host "Installing module: $m" -Foreground CYAN
					Install-Module -Name $m-Scope CurrentUser -AllowClobber -Force
					Import-Module -Name $m
					Update-Module -Name $m -Force
				}				 			 
			}
			else
			{
				write-host "Importing module: $m" -Foreground CYAN
				Import-Module $m
			}
			
		}
		else {
			write-host "Installing module: $m" -Foreground CYAN
			Install-Module -Name $m -Scope CurrentUser -AllowClobber -Force -SkipPublisherCheck
			Import-Module -Name $m 
		}
	}
}

#CONNECT TO EXCHANGEONLINE
$getsessions = Get-ConnectionInformation | Select-Object -Property State, Name
$isconnected = (@($getsessions) -like '@{State=Connected; Name=ExchangeOnline*').Count -gt 0

If ($isconnected -ne "True") {
	Try {
		Write-Host "Connecting to ExchangeOnline" -Foreground green
		Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -ShowBanner:$false
	}
	Catch {
		Write-Host "Connecting to ExchangeOnline Failed." -Foreground green
		Write-Error $_.Exception.Message
		Break
	}
}
else{
	Write-Host "ExchangeOnline Connected." -Foreground green
}

#DOWNLOAD GITHUB REPOSITORY
$Path = 'C:\TEMP\BPA'

if (Test-Path -Path $Path) {
	Remove-Item $Path -Recurse -Force
	New-Item $Path -Type Directory
	
	try{
		write-host "Downloading BPA scripts" -Foreground green
		git clone https://github.com/nubrixsecurity/bpa $Path
	}
	catch {
		write-host "Failed to fetch BPA scripts" -Foreground RED
		break
	}
}
else {
	New-Item $Path -Type Directory

	try{
		write-host "Downloading BPA scripts" -Foreground CYAN
		git clone https://github.com/nubrixsecurity/bpa
	}
	catch {
		write-host "Failed to fetch BPA scripts" -Foreground RED
		break
	}
}

#RUN SECURITY ASSESSMENTS
cd $Path
Write-Host "Running script: Microsoft Compliance Configuration Analyzer" -Foreground CYAN
.\MCCA.ps1

cd $Path
Write-Host "Running script: Microsoft Defender for Office 365" -Foreground CYAN
.\ORCA.ps1	

cd $Path
Write-Host "Running script: M365 Inspect" -Foreground CYAN
.\M365Inspect.ps1