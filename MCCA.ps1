#CHECK IF MODULES EXISTS

$Modules = @('ExchangeOnlineManagement',`
			 'MCCAPreview')

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
		}
		else {
			write-host "Installing module: $m" -Foreground CYAN
			Install-Module -Name $m -Scope CurrentUser -AllowClobber -Force
			Import-Module -Name $m 
		}
	}
}
#>

#CHECK IF PATH EXIST / DOWNLOAD GITHUB REPOSITORY
$Path = 'C:\TEMP\BPA\MCCA'

if (Test-Path -Path $Path) {
	Remove-Item $Path -Recurse -Force
	New-Item $Path -Type Directory
	git clone https://github.com/cammurray/orca $Path
	cd $Path 
	Get-MCCAReport
	Copy-Item "C:\Users\*\AppData\Local\Microsoft\MCCA\*.html" -Destination "C:\TEMP\BPA\MCCA\Outputs\"
} else {
    New-Item $Path -Type Directory
    git clone https://github.com/cammurray/orca $Path
	cd $Path 
	Get-MCCAReport
	Copy-Item "C:\Users\*\AppData\Local\Microsoft\MCCA\*.html" -Destination "C:\TEMP\BPA\MCCA\Outputs\"
}

