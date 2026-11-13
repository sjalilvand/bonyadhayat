# ============================================================
#  نصب و اجرای سایت ساخته‌شده (ویندوز / PowerShell)
#  اجرا:  PowerShell  →   .\setup.ps1
# ============================================================
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  نصب و راه‌اندازی سامانه" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""

# ---- ۱) بررسی Node.js (در صورت نبود، نصب خودکار با winget) ----
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Write-Host "→ Node.js یافت نشد؛ تلاش برای نصب با winget ..." -ForegroundColor Yellow
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        $node = Get-Command node -ErrorAction SilentlyContinue
    }
}
if (-not $node) {
    Write-Host "خطا: Node.js نصب نیست. ابتدا Node.js نسخه ۲۰ یا جدیدتر را از https://nodejs.org نصب کنید و دوباره اجرا کنید." -ForegroundColor Red
    exit 1
}
$nodeVersion = (node --version) -replace "v", ""
Write-Host "✓ Node.js نسخه $nodeVersion" -ForegroundColor Cyan

# ---- ۲) نصب وابستگی‌ها (فقط بار اول) ----
if (-not (Test-Path "node_modules")) {
    Write-Host "→ نصب وابستگی‌ها با npm (چند دقیقه طول می‌کشد) ..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) { Write-Host "خطا در نصب وابستگی‌ها" -ForegroundColor Red; exit 1 }
} else {
    Write-Host "✓ وابستگی‌ها از قبل نصب شده‌اند" -ForegroundColor Cyan
}

# ---- ۳) فایل .env ----
if (-not (Test-Path ".env")) {
    @"
DATABASE_URL=file:../db/custom.db
AUTH_SECRET=9e2ac369bbc52ab720ece6a39dd4527d94f7476cf4c8e081cd3576259f7b373b
"@ | Out-File -FilePath ".env" -Encoding utf8
    Write-Host "✓ فایل .env ساخته شد" -ForegroundColor Cyan
}

# ---- ۴) ساخت دیتابیس ----
New-Item -ItemType Directory -Force -Path "db" | Out-Null
Write-Host "→ ساخت و همگام‌سازی دیتابیس (prisma) ..." -ForegroundColor Yellow
npx prisma db push --accept-data-loss
if ($LASTEXITCODE -ne 0) { Write-Host "خطا در ساخت دیتابیس" -ForegroundColor Red; exit 1 }

# ---- ۵) داده‌های اولیه ----
if (-not (Test-Path "db\custom.db") -or ((Get-Item "db\custom.db").Length -lt 4096)) {
    Write-Host "→ بارگذاری داده‌های اولیه ..." -ForegroundColor Yellow
    npx tsx prisma/seed.ts
    if ($LASTEXITCODE -ne 0) { Write-Host "خطا در داده‌های اولیه" -ForegroundColor Red; exit 1 }
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  نصب کامل شد!" -ForegroundColor Green
Write-Host "  آدرس سایت:      http://localhost:3003" -ForegroundColor Yellow
Write-Host "  پنل مدیریت:     http://localhost:3003/admin" -ForegroundColor Yellow
Write-Host "  نام کاربری:     admin" -ForegroundColor Yellow
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "→ اجرای سامانه روی پورت 3003 (برای توقف Ctrl+C) ..." -ForegroundColor Yellow
npm run dev:3003
