#Requires -Version 7
<#
.SYNOPSIS
Runs the shared localswim service's CLI as Bot, with the Bot token for this one run only.

.DESCRIPTION
MobileFlow's work is tracked as cards on the "MobileFlow" board of Terry's shared localswim
service, board ID 12fe6a1f-50be-44df-bd82-85ff21b301c6. The service runs from C:\Projects\localswim;
its data is in the localswim state store, outside this repository. Its receipt, service.json, gives
the base URL and the directory holding the DPAPI-protected credentials. The script tries
%LOCALAPPDATA%\localswim-v2\service.json first and the older runtime copy in the localswim repo second.

This script reads the receipt, reads bot.json from the receipt's credential directory, decrypts its
token, sets LOCALSWIM_URL and LOCALSWIM_TOKEN at Process scope, runs localswim.exe with every
argument it was given, and then clears both variables. It never writes to the User or Machine
environment and never prints the token. Every localswim call an agent makes for MobileFlow on
Windows MUST use it, and the token MUST NOT be read any other way.

bot.json is localswim's launch credential format: one JSON object with exactly the members format
("localswim-credential"), format_version (the integer 1), role ("bot") and token_dpapi_hex. Its spec
is localswim's docs/windows-operations.md, "The service receipt and credential files". The script
refuses any other file.

Adapted from swimcoach's scripts/localswim.ps1 on 2026-11-26. There is no param block on purpose:
every argument goes to localswim.exe unchanged.

.EXAMPLE
pwsh -NoProfile -File scripts/localswim.ps1 card list 12fe6a1f-50be-44df-bd82-85ff21b301c6
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$serviceRoot = 'C:\Projects\localswim'
$exe = Join-Path $serviceRoot 'localswim.exe'
if (-not (Test-Path -LiteralPath $exe)) {
    throw "Missing $exe."
}

# Newest home first; the first receipt that exists wins.
$receiptCandidates = @()
if ($env:LOCALAPPDATA) {
    $receiptCandidates += Join-Path $env:LOCALAPPDATA 'localswim-v2\service.json'
}
$receiptCandidates += Join-Path $serviceRoot 'runtime\service.json'
$receiptFile = $receiptCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if ($null -eq $receiptFile) {
    throw "Missing the localswim service receipt; tried $($receiptCandidates -join ', ')."
}

# Reads the Bot token from bot.json, refusing any file that is not localswim-credential format 1
# for role bot. Follows localswim's Read-LocalswimToken (docs/windows-operations.md).
# The token MUST NOT reach any message or output.
function Read-BotToken([string]$File) {
    $ErrorActionPreference = 'Stop'
    $text = [IO.File]::ReadAllText($File)
    if ($text -notmatch '^\s*\{') {
        throw "Unsupported credential format in ${File}: not one JSON object."
    }
    # ConvertFrom-Json refuses member names that differ only in case.
    $credential = $text | ConvertFrom-Json
    $names = @($credential.PSObject.Properties | ForEach-Object Name)
    $expected = 'format', 'format_version', 'role', 'token_dpapi_hex'
    if ($names.Count -ne 4 -or @($names | Where-Object { $_ -cnotin $expected }).Count -ne 0) {
        throw "Unsupported credential format in ${File}: members are not exactly $($expected -join ', ')."
    }
    # Each string member MUST be checked as a string first: -cne with an array on its left filters
    # the array instead of comparing it, so ["bot"] or [] would pass.
    $version = $credential.format_version
    if ($credential.format -isnot [string] -or $credential.format -cne 'localswim-credential' -or
        -not ($version -is [int] -or $version -is [long]) -or $version -ne 1) {
        throw "Unsupported credential format in ${File}: not localswim-credential format_version 1."
    }
    if ($credential.role -isnot [string] -or $credential.role -cne 'bot') {
        throw "Unsupported credential format in ${File}: role is not bot."
    }
    # Checked before decryption, whose own error would repeat the malformed text.
    if ($credential.token_dpapi_hex -isnot [string] -or
        $credential.token_dpapi_hex -cnotmatch '^(?:[0-9a-f]{2})+\z') {
        throw "Unsupported credential format in ${File}: token_dpapi_hex is not lowercase hexadecimal."
    }
    $token = [Net.NetworkCredential]::new(
        '', (ConvertTo-SecureString -String $credential.token_dpapi_hex)).Password
    if ($token -cnotmatch '^[A-Za-z0-9_-]{43}\z') {
        throw "The token in $File is not 43 base64url characters."
    }
    $token
}

$receipt = [IO.File]::ReadAllText($receiptFile) | ConvertFrom-Json
$botFile = Join-Path $receipt.credential_directory 'bot.json'
if (-not (Test-Path -LiteralPath $botFile)) {
    throw "Missing $botFile. The service receipt names a credential directory without bot.json."
}
$botToken = Read-BotToken $botFile

$exitCode = 1
try {
    [Environment]::SetEnvironmentVariable('LOCALSWIM_URL', $receipt.base, 'Process')
    [Environment]::SetEnvironmentVariable('LOCALSWIM_TOKEN', $botToken, 'Process')
    & $exe @args
    $exitCode = $LASTEXITCODE
}
finally {
    [Environment]::SetEnvironmentVariable('LOCALSWIM_TOKEN', $null, 'Process')
    [Environment]::SetEnvironmentVariable('LOCALSWIM_URL', $null, 'Process')
    $botToken = $null
}
exit $exitCode
