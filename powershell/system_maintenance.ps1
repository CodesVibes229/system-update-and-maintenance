# powershell/system_maintenance.ps1
# Script PowerShell de maintenance système Windows

# === Configuration ===
$logDir = "..\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

$logFile = Join-Path $logDir ("maintenance_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")
$services = @("docker", "Spooler")

function Log {
    param ($message)
    $timestamp = Get-Date -Format "[yyyy-MM-dd HH:mm:ss]"
    $entry = "$timestamp $message"
    Write-Output $entry
    Add-Content -Path $logFile -Value $entry
}

Log "=== Début de la maintenance système ==="

# 1. Mise à jour via winget
if (Get-Command "winget" -ErrorAction SilentlyContinue) {
    Log "🔄 Mise à jour des applications via winget"
    try {
        winget upgrade --all --silent | Tee-Object -FilePath $logFile -Append
    } catch {
        Log "❌ Erreur lors de la mise à jour avec winget"
    }
} else {
    Log "⚠️ winget non disponible sur ce système"
}

# 2. Mises à jour Windows (si module disponible)
if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
    Import-Module PSWindowsUpdate
    Log "🔄 Recherche de mises à jour Windows"
    try {
        Get-WindowsUpdate -AcceptAll -Install -AutoReboot | Tee-Object -FilePath $logFile -Append
    } catch {
        Log "❌ Erreur lors des mises à jour Windows"
    }
} else {
    Log "⚠️ Module PSWindowsUpdate non installé. Tu peux l’ajouter avec : Install-Module -Name PSWindowsUpdate"
}

# 3. Nettoyage de fichiers temporaires
Log "🧹 Nettoyage de fichiers temporaires"
try {
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Log "✅ Dossiers TEMP nettoyés"
} catch {
    Log "❌ Erreur lors du nettoyage"
}

# 4. Redémarrage des services
foreach ($svc in $services) {
    Log "🔁 Redémarrage du service : $svc"
    try {
        Restart-Service -Name $svc -Force -ErrorAction Stop
        Log "✅ $svc redémarré"
    } catch {
        Log "❌ Impossible de redémarrer $svc"
    }
}

Log "✅ Maintenance terminée. Log : $logFile"
