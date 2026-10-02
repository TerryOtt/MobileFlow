[CmdletBinding()]
param(
    [string] $ThreadId = $env:CODEX_THREAD_ID,
    [string] $BoardPath = 'C:\Projects\localswim-state-store\MobileFlow\mobileflow-localswim.json'
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ThreadId)) {
    throw 'Pass the active Codex thread UUID with -ThreadId, or set CODEX_THREAD_ID.'
}
$ThreadId = ([guid]::Parse($ThreadId)).ToString()
$boardFile = (Resolve-Path -LiteralPath $BoardPath).Path
$board = Get-Content -LiteralPath $boardFile -Raw | ConvertFrom-Json
if ($board.project -ne 'MobileFlow') { throw 'The selected board is not MobileFlow.' }
$port = [int]$board.port
if ($port -lt 1 -or $port -gt 65535) { throw 'The board port is invalid.' }
$baseUrl = "http://127.0.0.1:$port"
$monitorRoot = 'C:\Projects\FGA\architecture-design'
$monitorScript = Join-Path $monitorRoot 'scripts\watch_localswim.py'
if (-not (Test-Path -LiteralPath $monitorScript)) { throw 'The shared JSON monitor is missing.' }
$serviceExecutable = (Get-Command localswim -ErrorAction Stop).Source
$uvExecutable = (Get-Command uv -ErrorAction Stop).Source
$null = Get-Command localswim-cli,codex -ErrorAction Stop
$env:PYTHONIOENCODING = 'utf-8'
$env:UV_CACHE_DIR = 'C:\Temp\localswim-uv-cache'
$null = New-Item -ItemType Directory -Path 'C:\Temp' -Force
$statusPath = 'C:\Temp\MobileFlow-localswim-monitor-status.json'
$targetPath = 'C:\Temp\MobileFlow-localswim-monitor-target.json'
$lockPath = 'C:\Temp\MobileFlow-localswim-monitor.lock'

function Get-MobileFlowService {
    try {
        $status = Invoke-RestMethod "$baseUrl/api/v001/status" -TimeoutSec 2
    } catch {
        return $null
    }
    if (-not $status.ok) { throw 'A service is listening, but its board is unhealthy.' }
    $servedBoard = Invoke-RestMethod "$baseUrl/api/v001/board" -TimeoutSec 2
    if ($servedBoard.project -ne 'MobileFlow') {
        throw "Port $port belongs to a different board. No service was started."
    }
    return $status
}

# Serialize this board's launch; the shared monitor has its own single-instance lock.
$launchMutex = [System.Threading.Mutex]::new($false, 'Local\MobileFlow-localswim-launch')
$ownsMutex = $false
try {
    try {
        $ownsMutex = $launchMutex.WaitOne(15000)
    } catch [System.Threading.AbandonedMutexException] {
        $ownsMutex = $true
    }
    if (-not $ownsMutex) { throw 'Another MobileFlow board launch is still running.' }
    $service = Get-MobileFlowService
    if ($null -eq $service) {
        $serviceProcess = Start-Process -FilePath $serviceExecutable -ArgumentList ('"{0}"' -f $boardFile) -WorkingDirectory (Split-Path -Parent $boardFile) -WindowStyle Hidden -RedirectStandardOutput 'C:\Temp\MobileFlow-localswim.out.log' -RedirectStandardError 'C:\Temp\MobileFlow-localswim.err.log' -PassThru
        for ($attempt = 0; $attempt -lt 40; $attempt++) {
            Start-Sleep -Milliseconds 250
            $service = Get-MobileFlowService
            if ($null -ne $service) { break }
            if ($serviceProcess.HasExited) { throw 'Board service exited; inspect its error log.' }
        }
        if ($null -eq $service) { throw 'Board service did not become healthy.' }
    }

    # Unique per-launch logs allow safe retargeting while the existing watcher keeps its logs open.
    $logSuffix = [guid]::NewGuid().ToString('N')
    $monitorArguments = @(
        'run', '--frozen', 'python', 'scripts/watch_localswim.py',
        '--board-path', ('"{0}"' -f $boardFile), '--board-label', '"MobileFlow localswim"',
        '--thread-id', $ThreadId, '--port', $port,
        '--status-path', $statusPath, '--target-path', $targetPath, '--lock-path', $lockPath
    )
    $monitorProcess = Start-Process -FilePath $uvExecutable -ArgumentList $monitorArguments -WorkingDirectory $monitorRoot -WindowStyle Hidden -RedirectStandardOutput "C:\Temp\MobileFlow-localswim-monitor-$logSuffix.out.log" -RedirectStandardError "C:\Temp\MobileFlow-localswim-monitor-$logSuffix.err.log" -PassThru
    $monitorReady = $false
    for ($attempt = 0; $attempt -lt 60; $attempt++) {
        Start-Sleep -Milliseconds 250
        if ((Test-Path -LiteralPath $statusPath) -and (Test-Path -LiteralPath $targetPath)) {
            $monitor = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
            $target = Get-Content -LiteralPath $targetPath -Raw | ConvertFrom-Json
            $liveProcess = Get-Process -Id $monitor.pid -ErrorAction SilentlyContinue
            if ($monitor.state -eq 'running' -and $monitor.board -eq $boardFile -and $target.threadId -eq $ThreadId -and $null -ne $liveProcess) {
                $monitorReady = $true
                break
            }
        }
        if ($monitorProcess.HasExited -and $monitorProcess.ExitCode -ne 0) {
            throw "JSON monitor failed; inspect C:\Temp\MobileFlow-localswim-monitor-$logSuffix.err.log."
        }
    }
    if (-not $monitorReady) { throw 'JSON monitor did not become healthy for this Codex thread.' }
    Write-Output "MobileFlow board: $baseUrl/"
    Write-Output "JSON monitor running (PID $($monitor.pid)), targeted at $ThreadId."
} finally {
    if ($ownsMutex) { $launchMutex.ReleaseMutex() }
    $launchMutex.Dispose()
}
