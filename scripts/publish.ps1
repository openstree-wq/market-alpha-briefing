# 매일 아침 실행: 새 브리핑 파일을 감지해 index.html을 재생성하고 GitHub에 push한다.
# Windows 작업 스케줄러에 등록해서 사용한다.

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$logFile = Join-Path $repoRoot "scripts\publish.log"
function Log($msg) {
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

try {
    & (Join-Path $PSScriptRoot "build-index.ps1")

    git add "*.html" "robots.txt"
    $changes = git status --porcelain
    if ([string]::IsNullOrWhiteSpace($changes)) {
        Log "변경 사항 없음. push 생략."
        exit 0
    }

    $dateStr = Get-Date -Format "yyyy-MM-dd"
    git commit -m "Update briefing archive $dateStr"
    git push origin main

    Log "push 완료 ($dateStr)"
}
catch {
    Log "오류 발생: $($_.Exception.Message)"
    exit 1
}
