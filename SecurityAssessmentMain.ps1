#START BPA - DOWNLOAD GITHUB REPOSITORY
$Path = 'C:\TEMP\BPA\'
if (Test-Path -Path $Path) {
	Remove-Item $Path -Recurse -Force
	New-Item $Path -Type Directory
	git clone https://github.com/vicantsolutions/BPA $Path
	cd $Path
}
else {
	New-Item $Path -Type Directory
	git clone https://github.com/vicantsolutions/BPA $Path
	cd $Path
}

#CHECK INSTALLED MODULES
param (
    [Parameter(Mandatory = $false,
        HelpMessage = 'Skips required module check. Designed for troubleshooting purposes.')]
    [switch] $SkipModuleCheck,
    [Parameter(Mandatory = $false,
        HelpMessage = "Report Output Format")]
    [ValidateSet("All", "HTML", "CSV", "XML", "JSON",
        IgnoreCase = $true)]
    [string] $reportType = "All"
 
)

$creds = Get-Credential 
$Auth = "MFA"

$global:orgInfo = $null
$out_path = $OutPath
$selected_inspectors = $SelectedInspectors
$excluded_inspectors = $ExcludedInspectors

cd C:\TEMP\BPA\M365Inspect\
. .\Write-ErrorLog.ps1

$MaximumFunctionCount = 32768

Function Connect-Services {
    # Log into every service prior to the analysis.
    If ($auth -EQ "MFA") {
        Try {
            Write-Output "Connecting to Microsoft Graph"
            Connect-MgGraph -Credential $creds -ContextScope Process -Scopes "AuditLog.Read.All", "Policy.Read.All", "Directory.Read.All", "IdentityProvider.Read.All", "Organization.Read.All", "Securityevents.Read.All", "ThreatIndicators.Read.All", "SecurityActions.Read.All", "User.Read.All", "UserAuthenticationMethod.Read.All", "MailboxSettings.Read", "DeviceManagementManagedDevices.Read.All", "DeviceManagementApps.Read.All", "UserAuthenticationMethod.ReadWrite.All", "DeviceManagementServiceConfig.Read.All", "DeviceManagementConfiguration.Read.All" -Verbose
            If ((Get-Module -Name Microsoft.Graph.Authentication) -lt [version]2.0.0){
                Select-MgProfile -Name beta -Verbose
            }
            $global:orgInfo = Get-MgOrganization
            $global:tenantDomain = (($global:orgInfo).VerifiedDomains |  Where-Object { ($_.Name -like "*.onmicrosoft.com") -and ($_.Name -notlike "*mail.onmicrosoft.com") }).Name
            Write-Output "Connected via Graph to $(($global:orgInfo).DisplayName)"
        }
        Catch {
            Write-Output "Connecting to Microsoft Graph Failed."
            Write-Error $_.Exception.Message
            Break
        }
        Try {
            Write-Output "Connecting to Exchange Online"
            Connect-ExchangeOnline -Credential $creds -ShowBanner:$false -Verbose
        }
        Catch {
            Write-Output "Connecting to Exchange Online Failed."
            Write-Error $_.Exception.Message
            Break
        }
        Try {
            Write-Output "Connecting to SharePoint Service"
            $org_name = ($global:tenantDomain -split '.onmicrosoft.com')[0]
            Connect-SPOService -Url "https://$org_name-admin.sharepoint.com"
        }
        Catch {
            Write-Output "Connecting to SharePoint Service Failed."
            Write-Error $_.Exception.Message
            Break
        }
        Try {
            Write-Output "Connecting to Microsoft Teams"
            Connect-MicrosoftTeams -Credential $creds
        }
        Catch {
            Write-Output "Connecting to Microsoft Teams Failed."
            Write-Error $_.Exception.Message
            Break
        }
        Try {
            Write-Output "Connecting to Security and Compliance Center"
            Connect-IPPSSession -Credential $creds
        }
        Catch {
            Write-Output "Connecting to Security and Compliance Center Failed."
            Write-Error $_.Exception.Message
            Break
        }
    }
    Else {
        $global:orgInfo = Get-MgOrganization
        $global:tenantDomain = (($global:orgInfo).VerifiedDomains | Where-Object { $_.Name -match 'onmicrosoft.com' })[0].Name
    }
}

#Function to change color of text on errors for specific messages
Function Colorize($ForeGroundColor) {
    $color = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForeGroundColor
  
    if ($args) {
        Write-Output $args
    }
  
    $Host.UI.RawUI.ForegroundColor = $color
}


Function Confirm-Close {
    Read-Host "Press Enter to Exit"
    Exit
}

Function Confirm-InstalledModules {
    #Check for required Modules and versions; Prompt for install if missing and import.
    $ExchangeOnlineManagement = @{ Name = "ExchangeOnlineManagement"; MinimumVersion = "2.0.5" }
    $SharePoint = @{ Name = "Microsoft.Online.SharePoint.PowerShell"; MinimumVersion = "16.0.22601.12000" }
    $Graph = @{ Name = "Microsoft.Graph"; MinimumVersion = "1.9.6" }
    $MSTeams = @{ Name = "MicrosoftTeams"; MinimumVersion = "4.4.1" }
    $psGet = @{ Name = "PowerShellGet"; RequiredVersion = "2.2.5" }

    Try {
        $psGetVersion = Get-InstalledModule -Name PowerShellGet -ErrorAction Stop

        If ($psGetVersion.Version -lt '2.2.5') {
            Write-Host "[-] " -ForegroundColor Red -NoNewline
            Write-Warning "PowerShellGet is not the correct version. Please install using the following command:"
            Write-Host "Update-Module " -ForegroundColor Yellow -NoNewline
            Write-Host "-Name " -ForegroundColor Gray -NoNewline
            Write-Host "PowerShellGet " -ForegroundColor White -NoNewline
            Write-Host '-Force' -ForegroundColor Gray
            $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
            if (-not $IsAdmin) {
                Write-Warning "PowerShellGet is not the correct version. Please install using the following command:"
                Write-Host "Update-Module " -ForegroundColor Yellow -NoNewline
                Write-Host "-Name " -ForegroundColor Gray -NoNewline
                Write-Host "PowerShellGet " -ForegroundColor White -NoNewline
                Write-Host '-Force' -ForegroundColor Gray
            }
            Else {
                Write-Host "Installing PowerShellGet`n" -ForegroundColor Magenta
                Install-Module -Name 'PowerShellGet' -AllowPrerelease -AllowClobber -Force -MinimumVersion '2.2.5'
            }
        }
    }
    Catch {
        $exc = $_
        if ($exc -like "*No match was found for the specified search criteria and module names 'powershellget'*") {
            Write-Host "[-] " -ForegroundColor Red -NoNewline
            Write-Warning "PowerShellGet was not installed via PowerShell Gallery. Please install using the following command:"
            Write-Host "Install-Module " -ForegroundColor Yellow -NoNewline
            Write-Host "-Name " -ForegroundColor Gray -NoNewline
            Write-Host "PowerShellGet " -ForegroundColor White -NoNewline
            Write-Host "-RequiredVersion " -ForegroundColor Gray -NoNewline
            Write-Host '2.2.5 ' -ForegroundColor White -NoNewline
            Write-Host '-Force' -ForegroundColor Gray
        }
    }

    $modules = @($psGet, $ExchangeOnlineManagement, $Graph, $SharePoint, $MSTeams)
    $count = 0

    Write-Output "Verifying environment. `n"

    foreach ($module in $modules) {
        $installedVersion = [Version](((Get-InstalledModule -Name $module.Name).Version -split "-")[0])

        If (($module.Name -eq (Get-InstalledModule -Name $module.Name).Name) -and (([Version]$module.MinimumVersion -le $installedVersion))) {
            If ($PSVersionTable.PSVersion.Major -eq 5) {
                Write-Host "Environment is $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
                Write-Host "`t[+] " -NoNewLine -ForeGroundColor Green
                Write-Output "$($module.Name) is installed."
                
                If ($module.Name -ne 'Microsoft.Graph') {
                    Write-Host "`tImporting $($module.Name)" -ForeGroundColor Green
                    Import-Module -Name $module.Name | Out-Null
                }
                Else {
                    Write-Host "`tImporting Microsoft.Graph" -ForeGroundColor Green
                    Import-Module -Name Microsoft.Graph.Identity.DirectoryManagement | Out-Null
                    Import-Module -Name Microsoft.Graph.Identity.SignIns | Out-Null
                    Import-Module -Name Microsoft.Graph.Users | Out-Null
                    Import-Module -Name Microsoft.Graph.Applications | Out-Null
                }
            }
            Elseif ($PSVersionTable.PSVersion.Major -ge 6) {
                If ($IsWindows) {
                    Write-Host "Environment is $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
                    Write-Host "`t[+] " -NoNewLine -ForeGroundColor Green
                    Write-Output "$($module.Name) is installed."

                    If (($module.Name -ne 'Microsoft.Graph') -and ($module.Name -ne 'ExchangeOnlineManagement')) {
                        Try {
                            Write-Host "`tImporting $($module.Name)" -ForeGroundColor Green
                            Import-Module -Name $module.Name -UseWindowsPowerShell -WarningAction SilentlyContinue | Out-Null
                        }
                        Catch {
                            Write-Warning "Error message: $_"
                            $message = $_.ToString()
                            $exception = $_.Exception
                            $strace = $_.ScriptStackTrace
                            $failingline = $_.InvocationInfo.Line
                            $positionmsg = $_.InvocationInfo.PositionMessage
                            $pscommandpath = $_.InvocationInfo.PSCommandPath
                            $failinglinenumber = $_.InvocationInfo.ScriptLineNumber
                            $scriptname = $_.InvocationInfo.ScriptName
                            Write-Verbose "Write to log"
                            Write-ErrorLog -message $message -exception $exception -scriptname $scriptname -failinglinenumber $failinglinenumber -failingline $failingline -pscommandpath $pscommandpath -positionmsg $pscommandpath -stacktrace $strace
                            Write-Verbose "Errors written to log"
                        }
                    }
                    Else {
                        Try {
                            Write-Host "`tInporting ExchangeOnlineManagement"
                            Import-Module -Name ExchangeOnlineManagement | Out-Null
                            Write-Host "`tImporting Microsoft.Graph" -ForeGroundColor Green
                            Import-Module -Name Microsoft.Graph.Identity.DirectoryManagement | Out-Null
                            Import-Module -Name Microsoft.Graph.Identity.SignIns | Out-Null
                            Import-Module -Name Microsoft.Graph.Users | Out-Null
                            Import-Module -Name Microsoft.Graph.Applications | Out-Null
                        }
                        Catch {
                            Write-Warning "Error message: $_"
                            $message = $_.ToString()
                            $exception = $_.Exception
                            $strace = $_.ScriptStackTrace
                            $failingline = $_.InvocationInfo.Line
                            $positionmsg = $_.InvocationInfo.PositionMessage
                            $pscommandpath = $_.InvocationInfo.PSCommandPath
                            $failinglinenumber = $_.InvocationInfo.ScriptLineNumber
                            $scriptname = $_.InvocationInfo.ScriptName
                            Write-Verbose "Write to log"
                            Write-ErrorLog -message $message -exception $exception -scriptname $scriptname -failinglinenumber $failinglinenumber -failingline $failingline -pscommandpath $pscommandpath -positionmsg $pscommandpath -stacktrace $strace
                            Write-Verbose "Errors written to log"
                        }
                    }
                }
                Else {
                    Write-Host "We're sorry, due to various module dependency requirements, this tool will not work on a non-Windows operating system." -ForegroundColor Yellow
                    Exit
                }
            }
            $count ++
        }
        Else {
            $message = Write-Output "`n$($module.Name) is not installed."
            $message1 = Write-Output "The module may be installed by running `"Install-Module -Name $($module.Name) -AllowPrerelease -AllowClobber -Force -MinimumVersion $($module)`" in an elevated PowerShell window."
            Colorize Red ($message)
            Colorize Yellow ($message1)
            $install = Read-Host -Prompt "Would you like to attempt installation now? (Y|N)"
            If ($install -eq 'y') {
                Install-Module -Name $module.Name -AllowPrerelease -AllowClobber -Scope CurrentUser -Force -MinimumVersion $module
                $count ++
            }
        }
    }

    If ($count -lt 5) {
        Write-Output ""
        Write-Output ""
        $message = Write-Output "Dependency checks failed. Please install all missing modules before running this script."
        Colorize Red ($message)
        Confirm-Close
    }
    Else {
        Connect-Services
    }
}
	
cd $Path
Write-Host "Running script: M365 Inspect" -Foreground green
.\M365Inspect.ps1

cd $Path
Write-Host "Running script: Microsoft Compliance Configuration Analyzer" -Foreground green
.\MCCA.ps1

cd $Path
Write-Host "Running script: Microsoft Defender for Office 365" -Foreground green
.\ORCA.ps1	