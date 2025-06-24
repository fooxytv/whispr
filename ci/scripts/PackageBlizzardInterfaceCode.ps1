param (
    [string]$Version,
    [string]$BuildNumber
)

$rootDirectory = "$(Get-Location)"
$targetDirectory = "$rootDirectory\code"
$folderToZip = "$rootDirectory\BlizzardInterfaceCode"

if (-not $Version -or -not $BuildNumber) {
    Write-Output "Both version and build number must be provided"
    exit
}

$zipFileName = "BlizzardInterfaceCode-$Version.$BuildNumber.zip"
$zipFilePath = "$targetDirectory\$zipFileName"

if (Test-path $folderToZip) {
    if (-not (Test-Path $targetDirectory)) {
        New-Item -ItemType Directory -Path $targetDirectory
    }
    Compress-Archive -Path $folderToZip -DestinationPath $zipFilePath
    Write-Output "Folder zipped and moved to $zipFilePath"
} else {
    Write-Output "Folder $folderToZip does not exist"
    exit 1
}
