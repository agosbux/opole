# 🔧 FIX IMPORTS - Simple replace for QuestionModel
# Ejecutar desde la raíz del proyecto Opole

$old = "package:opole/pages/reel_questions/model/question_model.dart"
$new = "package:opole/core/supabase/models/question_model.dart"
$legacy = "lib/pages/reel_questions/model/question_model.dart"

Write-Host "🔍 Buscando archivos con import legacy..." -ForegroundColor Cyan

# Buscar y reemplazar en todos los .dart de lib/
Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match [regex]::Escape($old)) {
        Write-Host "  ✏️  Fixing: $($_.Name)" -ForegroundColor Yellow
        $content -replace [regex]::Escape($old), $new | Set-Content $_.FullName -Encoding UTF8
        Write-Host "  ✅ Done: $($_.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "🗑️  Eliminando archivo legacy..." -ForegroundColor Cyan
if (Test-Path $legacy) {
    Remove-Item $legacy -Force
    Write-Host "  ✅ Deleted: $legacy" -ForegroundColor Green
} else {
    Write-Host "  ℹ️  Ya no existe: $legacy" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "🎯 Listo. Ahora ejecutá:" -ForegroundColor Cyan
Write-Host "  flutter clean && flutter pub get && flutter analyze" -ForegroundColor White