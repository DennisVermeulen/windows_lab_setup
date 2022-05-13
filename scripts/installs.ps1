param(
    [Parameter(Mandatory = $False)]
    [string]
    $branch = "master",

    [Parameter(Mandatory = $False)]
    [switch]
    $restart,
    
    [Parameter(Mandatory = $False)]
    [string]
    $additionalPreScript = "",
    
    [Parameter(Mandatory = $False)]
    [string]
    $additionalPostScript = "",

    [Parameter(Mandatory = $True)]
    [string]
    $name,

    [Parameter(Mandatory = $False)]
    [string]
    $authToken = $null,

    [Parameter(Mandatory = $False)]
    [string]
    $debugScripts
)

if ($debugScripts -eq "true") {
    New-Item -ItemType File -Path "c:\enableDebugging"
    $DebugPreference = "Continue"
}

if (-not $restart) {
    # Handle additional script
    if ($additionalPreScript -ne "") {
        [DownloadWithRetry]::DoDownloadWithRetry($additionalPreScript, 5, 10, $authToken, 'c:\scripts\additionalPreScript.ps1', $false)
        & 'c:\scripts\additionalPreScript.ps1' -branch "$branch" -authToken "$authToken"
    }
}
else {
    # Handle additional script
    if ($additionalPreScript -ne "") {
        & 'c:\scripts\additionalPreScript.ps1' -branch "$branch" -authToken "$authToken" -restart 
    }
}

if (-not $restart) {
    # Setup profile
    Write-Debug "Download profile file"
    [DownloadWithRetry]::DoDownloadWithRetry("https://raw.githubusercontent.com/DennisVermeulen/windows_lab_setup/main/scripts/profile.ps1", 5, 10, $null, $PROFILE.AllUsersAllHosts, $false)
    
    # SSH and Choco setup
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    choco feature enable -n allowGlobalConfirmation
    choco install --no-progress --limit-output vscode
    choco install --no-progress --limit-output googlechrome
    choco install --no-progress --limit-output vagrant
    choco install --no-progress --limit-output docker-desktop
    choco install --no-progress --limit-output git
    choco install --no-progress --limit-output putty
    
    net localgroup docker-users "mosadex" /ADD 
    shutdown /r
    
    }
