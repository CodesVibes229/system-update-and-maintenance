#!/bin/bash

# system_maintenance.sh
# Script Bash de maintenance système (Linux)

# === Configuration ===
LOG_DIR="../logs"
LOG_FILE="$LOG_DIR/maintenance_$(date '+%Y%m%d_%H%M%S').log"
SERVICES=("docker" "nginx")

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Début de la maintenance système ==="

# Détection du gestionnaire de paquets
if command -v apt >/dev/null 2>&1; then
    PACKAGE_MANAGER="apt"
elif command -v dnf >/dev/null 2>&1; then
    PACKAGE_MANAGER="dnf"
else
    log "❌ Aucun gestionnaire de paquets compatible trouvé (apt ou dnf)"
    exit 1
fi

# Mise à jour système
log "🔄 Mise à jour du système avec $PACKAGE_MANAGER"

if [ "$PACKAGE_MANAGER" == "apt" ]; then
    sudo apt update && sudo apt upgrade -y | tee -a "$LOG_FILE"
    sudo apt autoremove -y | tee -a "$LOG_FILE"
    sudo apt clean | tee -a "$LOG_FILE"
elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
    sudo dnf upgrade --refresh -y | tee -a "$LOG_FILE"
    sudo dnf autoremove -y | tee -a "$LOG_FILE"
    sudo dnf clean all | tee -a "$LOG_FILE"
fi

# Redémarrage des services
for svc in "${SERVICES[@]}"; do
    log "🔁 Redémarrage du service : $svc"
    sudo systemctl restart "$svc" && log "✅ $svc redémarré"
done

log "✅ Maintenance terminée. Log : $LOG_FILE"
