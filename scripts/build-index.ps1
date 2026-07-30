# Market Alpha Briefing - index.html 자동 생성 스크립트
# 리포지토리 루트에 있는 YYYYMMDD_MarketAlphaBriefing_vN.html 파일들을 스캔해
# 날짜별 아카이브 index.html을 생성한다.

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$pattern = '^(?<date>\d{8})_MarketAlphaBriefing_v(?<ver>\d+)\.html$'
$files = Get-ChildItem -Path $repoRoot -Filter "*.html" | Where-Object { $_.Name -match $pattern -and $_.Name -ne "index.html" }

if ($files.Count -eq 0) {
    Write-Host "브리핑 파일이 없습니다. index.html 생성을 건너뜁니다."
    exit 0
}

# 날짜별로 그룹핑 -> 각 날짜의 모든 버전 정보 보관 (최신순 정렬)
$byDate = @{}
foreach ($f in $files) {
    if ($f.Name -match $pattern) {
        $d = $Matches['date']
        $v = [int]$Matches['ver']
        if (-not $byDate.ContainsKey($d)) { $byDate[$d] = @() }
        $byDate[$d] += [PSCustomObject]@{ Ver = $v; Name = $f.Name }
    }
}

$dates = $byDate.Keys | Sort-Object -Descending
$latestDate = $dates[0]
$latestVer = ($byDate[$latestDate] | Sort-Object Ver -Descending)[0]
$latestFile = $latestVer.Name

function Format-DateKorean($d) {
    $y = $d.Substring(0,4); $m = $d.Substring(4,2); $day = $d.Substring(6,2)
    return "$y.$m.$day"
}

$archiveItemsHtml = ""
$monthGroups = $dates | Group-Object { $_.Substring(0,6) }
foreach ($mg in $monthGroups) {
    $groupYear = $mg.Name.Substring(0,4)
    $groupMonth = [int]$mg.Name.Substring(4,2)
    $archiveItemsHtml += "      <h3 class=`"month-header`">${groupYear}년 ${groupMonth}월</h3>`n      <ul class=`"archive-list`">`n"
    foreach ($d in $mg.Group) {
        $versions = $byDate[$d] | Sort-Object Ver -Descending
        $top = $versions[0]
        $dayLabel = "$([int]$d.Substring(6,2))일"
        $extraVersions = $versions | Select-Object -Skip 1
        $subLinksHtml = ""
        if ($extraVersions.Count -gt 0) {
            $links = $extraVersions | ForEach-Object { "<a href=`"$($_.Name)`">v$($_.Ver)</a>" }
            $subLinksHtml = "<span class=`"old-versions`">이전 버전: $([string]::Join(' · ', $links))</span>"
        }
        $archiveItemsHtml += @"
        <li class="archive-item">
          <a class="archive-link" href="$($top.Name)">
            <span class="archive-date">$dayLabel</span>
            <span class="archive-arrow">→</span>
          </a>
          $subLinksHtml
        </li>
"@
    }
    $archiveItemsHtml += "      </ul>`n"
}

$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm"
$latestDateLabel = Format-DateKorean $latestDate

$html = @"
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
<meta name="robots" content="noindex, nofollow">
<title>Market Alpha Briefing | LUPE — Archive</title>
<style>
  :root{
    --lupe-red:#C1001B;
    --lupe-dark:#1A1A1A;
    --lupe-mid:#4A4A4A;
    --bg:#fff;
  }
  *{box-sizing:border-box;}
  body{
    margin:0; padding:0; background:var(--bg); color:var(--lupe-dark);
    font-family:'Noto Sans KR', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    font-size:16px; line-height:1.75;
  }
  header{
    background:var(--lupe-dark); color:#fff; padding:24px 20px;
  }
  header .brand{ font-size:13px; letter-spacing:.08em; color:#ccc; }
  header h1{ margin:6px 0 0; font-size:22px; }
  main{ max-width:640px; margin:0 auto; padding:24px 20px 60px; }
  .featured{
    display:block; text-decoration:none; color:#fff;
    background:var(--lupe-red); border-radius:12px; padding:22px 20px;
    margin-bottom:32px;
  }
  .featured .label{ font-size:12px; opacity:.85; }
  .featured .date{ font-size:26px; font-weight:700; margin:4px 0 8px; }
  .featured .cta{ font-size:15px; font-weight:600; }
  h2.section-title{
    font-size:14px; color:var(--lupe-mid); border-bottom:2px solid var(--lupe-red);
    padding-bottom:8px; margin:0 0 12px;
  }
  h3.month-header{
    font-size:13px; color:var(--lupe-mid); margin:20px 0 4px;
  }
  h3.month-header:first-of-type{ margin-top:0; }
  ul.archive-list{ list-style:none; margin:0; padding:0; }
  li.archive-item{ border-bottom:1px solid #eee; padding:12px 0; }
  a.archive-link{
    display:flex; justify-content:space-between; align-items:center;
    text-decoration:none; color:var(--lupe-dark); font-size:16px; padding:6px 0;
  }
  a.archive-link .archive-arrow{ color:var(--lupe-red); }
  span.old-versions{ display:block; font-size:12px; color:var(--lupe-mid); margin-top:2px; }
  span.old-versions a{ color:var(--lupe-mid); }
  footer{ text-align:center; font-size:12px; color:#999; margin-top:40px; }
</style>
</head>
<body>
<header>
  <div class="brand">LUPE / HELIOS MOMENTUM</div>
  <h1>Market Alpha Briefing Archive</h1>
</header>
<main>
  <a class="featured" href="$latestFile">
    <div class="label">최신 브리핑</div>
    <div class="date">$latestDateLabel</div>
    <div class="cta">오늘의 브리핑 보기 →</div>
  </a>

  <h2 class="section-title">지난 브리핑</h2>
$archiveItemsHtml

  <footer>Generated $generatedAt · © $(Get-Date -Format yyyy) LUPE</footer>
</main>
</body>
</html>
"@

Set-Content -Path (Join-Path $repoRoot "index.html") -Value $html -Encoding UTF8
"User-agent: *`nDisallow: /" | Set-Content -Path (Join-Path $repoRoot "robots.txt") -Encoding ASCII

Write-Host "index.html 생성 완료 (최신: $latestDateLabel, 총 $($dates.Count)일치)"
