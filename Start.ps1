#RUN SCRIPT ON POWERSHELL 5.1

#INPUT VARIABLES
$userPrincipalName = $(Write-Host "Enter User Name: " -f yellow -NoNewLine; Read-Host)
$fullDomain = ($userPrincipalName -split "@")[1]
$inputOrg = ($fullDomain -split ".c")[0]

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

#UNBLOCK FILES
$files = Get-ChildItem $pathDate -Recurse -File

foreach ($file in $files) {
    Unblock-File -Path $file.FullName -Confirm:$false
}

#COPY CUSTOM FILE TO NEW LOCATION
$copyFile = $clonePathC1+'Get-M365SATChecks.ps1'
Copy-Item $copyFile -Destination '$clonePathM365SAT\inspectors\'

$copyFile = $clonePathC1+'M365SAT.psm1'
Copy-Item $copyFile -Destination $clonePathM365SAT

$copyFile = $clonePathC1+'M365SATTester.ps1'
Copy-Item $copyFile -Destination $clonePathM365SAT

#RUN M365SAT
Set-Location $clonePathM365SAT
.\M365SATTester.ps1 $outPath $userPrincipalName

#OPEN THE HTML REPORT
$folder = Get-ChildItem -Path $outPath -Directory | Where-Object {$_.Name -match '\d+$'}
$reportPath = $outPath+$folder
$HTML = Get-ChildItem $reportPath -Filter "*.html"

Set-Location $reportPath
Start-Process $HTML
