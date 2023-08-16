$MaximumFunctionCount = 32768

#CHECK IF MODULES EXISTS
$Modules = @('Az',`
			 'PowerShellGet',`
			 'ExchangeOnlineManagement',`
			 'Microsoft.Online.SharePoint.PowerShell',`
			 'Microsoft.Graph',`
			 'Microsoft.Graph.Beta',`
			 'MicrosoftTeams',`
			 'PoShLog',`
			 'posh-git')

$MaximumFunctionCount = 32768

foreach($m in $Modules){
	# If module is imported say that and do nothing
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
			if($m -eq 'Az'){
				try{
					write-host "Importing module: $m" -Foreground CYAN
					Import-Module -Name $m
				}
				catch{
					write-host "Installing module: $m" -Foreground CYAN
					Install-Module -Name $m-Scope CurrentUser -AllowClobber -Force
					Import-Module -Name $m
				}				 			 
			}
			else{
				write-host "Installing module: $m" -Foreground CYAN
				Install-Module -Name $m -Scope CurrentUser -Force -SkipPublisherCheck
				Import-Module -Name $m 
			}
		}
	}
}

#CHECK IF PATH EXIST / DOWNLOAD GITHUB REPOSITORY
$Path = 'C:\TEMP\BPA\M365SAT'
if (Test-Path -Path $Path) {
	Remove-Item $Path -Recurse -Force
	New-Item $Path -Type Directory
	git clone https://github.com/asterictnl-lvdw/M365SAT $Path
	cd $Path 
	.\M365SATTester.ps1		
} else {
    New-Item $Path -Type Directory
    git clone https://github.com/asterictnl-lvdw/M365SAT $Path
	cd $Path 
	.\M365SATTester.ps1
}
