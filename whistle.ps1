<#
.SYNOPSIS
    Download, create and provision an Ubuntu WSL2 instance.
.DESCRIPTION
    This script downloads a user-specified Ubuntu WSL2 image, then creates and
    provisions a WSL2 instance using the downloaded image.
.PARAMETER WslDistroName
    User-chosen name for the WSL2 instance to be created.

    Example values: whistleblower, heavens-arena
    Default: whistleblower
.PARAMETER ReleaseName
    Ubuntu release name. For available WSL releases, see the Ubuntu WSL images page at
    https://cloud-images.ubuntu.com/wsl/

    Example values: noble, jammy
    Default: noble
.PARAMETER ReleaseTag
    Ubuntu release tag. Available release tags are found inside the directory of the
    specified release on the Ubuntu WSL images page.

    Example values: current, 20241008
    Default: current
.PARAMETER ReleaseArch
    Architecture of the WSL image to be downloaded.

    Example values: amd64, arm64
    Default: amd64
.PARAMETER SetupArgs
    Arguments for the setup script `whistle.bash`.
    Due to powershell's parsing limitations, this needs to be enclosed in _both_
    double quotes and single quotes.
    Use "'-h'" as the argument to see the arguments documentation.

    Example values: "'-h'", "'-b python3'", "'-u dragondive -b copy-ssh-keys'"
    Default: ""
#>
param
(
    [Parameter(HelpMessage="User-chosen name for the WSL2 instance to be created.")]
    [string]$WslDistroName = "whistleblower",

    [Parameter(HelpMessage="Ubuntu release name.")]
    [string]$ReleaseName = "noble",

    [Parameter(HelpMessage="Ubuntu release tag.")]
    [string]$ReleaseTag = "current",

    [Parameter(HelpMessage="Architecture of the WSL image to be downloaded.")]
    [string]$ReleaseArch = "amd64",

    [Parameter(HelpMessage="Arguments for the setup script whistle.bash")]
    [string]$SetupArgs = ""
)

$WslUbuntuUrl = "https://cloud-images.ubuntu.com/wsl"
$ImageName = "ubuntu-$ReleaseName-wsl-$ReleaseArch-ubuntu.rootfs.tar.gz"

$ImageUrl = "$WslUbuntuUrl/$ReleaseName/$ReleaseTag/$ImageName"
$SaveDir = "$env:LOCALAPPDATA/whistle"
$ImagePath = "$SaveDir/$ImageName"

[System.IO.Directory]::CreateDirectory($SaveDir) | Out-Null
if (!(Test-Path($ImagePath)))
{
    Write-Host "Downloading WSL Ubuntu image '$ReleaseName' to '$SaveDir'..."
    (New-Object Net.WebClient).DownloadFile($ImageUrl, $ImagePath)
}
else
{
    Write-Host "WSL Ubuntu image '$ReleaseName' already exists, skipping download."
}

$ShareEnvironmentVariableUsername = "USERNAME/u"
if (-not ($env:WSLENV -and $env:WSLENV -match [regex]::Escape($ShareEnvironmentVariableUsername)))
{
    Write-Host "Setting up WSLENV variable to share Windows USERNAME with WSL."
    $env:WSLENV += ":$ShareEnvironmentVariableUsername"
}

$WslPackagesDir = "$env:LOCALAPPDATA/Packages/WSL"
[System.IO.Directory]::CreateDirectory($WslPackagesDir) | Out-Null
wsl --import $WslDistroName $WslPackagesDir/$WslDistroName $ImagePath
if ($LASTEXITCODE -ne 0)
{
    throw "Failed to import WSL Ubuntu image '$ReleaseName' to '$WslDistroName'."
}
Write-Host "Successfully imported WSL Ubuntu image '$ReleaseName' to '$WslDistroName'."

# Install vscode on Windows because we will use inside WSL2. This is more convenient
# and flexible than the direct installation inside WSL2.
winget install --exact --verbose --accept-package-agreements --accept-source-agreements `
--version 1.93.0 --force <# prevent "upgrade" to 1.94.0 due to this bug: https://github.com/microsoft/vscode/issues/230584 #> `
--id Microsoft.VisualStudioCode

$ScriptDir = "$env:TEMP"
Copy-Item -Path $(Join-Path $PWD "whistle.bash") -Destination $ScriptDir
Set-Location -Path $ScriptDir
wsl --distribution $WslDistroName -- bash -c "./whistle.bash $SetupArgs"
wsl --terminate $WslDistroName
