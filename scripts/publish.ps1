# 매일 아침 실행: 새 브리핑 파일을 감지해 index.html을 재생성하고 GitHub에 push한다.
# 하루에 한 번 오늘자 브리핑 발행이 완료되면 금일 추가 감지를 생략한다.

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$logFile = Join-Path $repoRoot "scripts\publish.log"
function Log($msg) {
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

$todayStr = Get-Date -Format "yyyyMMdd"
$lastPublishedFile = Join-Path $repoRoot "scripts\.last_published_date"

if (-not $Force -and (Test-Path $lastPublishedFile)) {
    $lastDate = (Get-Content $lastPublishedFile -Raw).Trim()
    if ($lastDate -eq $todayStr) {
        Log "오늘자($todayStr) 브리핑이 이미 발행되었습니다. 금일 추가 감지를 생략합니다."
        exit 0
    }
}

try {
    $briefingPattern = '\d{8}_MarketAlphaBriefing_(.*_)?v\d+\.html'
    $briefingChanges = git status --porcelain | Where-Object { $_ -match $briefingPattern }
    if (-not $briefingChanges) {
        Log "브리핑 파일 변경 없음. push 생략."
        exit 0
    }

    & (Join-Path $PSScriptRoot "build-index.ps1")

    git add "*.html" "robots.txt"

    $dateStr = Get-Date -Format "yyyy-MM-dd"
    git commit -m "Update briefing archive $dateStr"
    git push origin main

    Set-Content -Path $lastPublishedFile -Value $todayStr -Encoding ASCII
    Log "push 완료 ($dateStr) - 금일 브리핑 발행 완료 기록됨."
}
catch {
    Log "오류 발생: $($_.Exception.Message)"
    exit 1
}
