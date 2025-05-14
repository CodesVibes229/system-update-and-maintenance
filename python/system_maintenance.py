#!/usr/bin/env python3

import subprocess
import os
import datetime
import argparse
import shutil
from pathlib import Path

# === Configuration ===
SERVICES = ["docker", "nginx"]
LOG_DIR = Path("../logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / f"maintenance_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

def log(message):
    timestamp = datetime.datetime.now().strftime("[%Y-%m-%d %H:%M:%S]")
    full_message = f"{timestamp} {message}"
    print(full_message)
    with open(LOG_FILE, "a") as f:
        f.write(full_message + "\n")

def run_command(command, dry_run=False):
    log(f"🔧 Commande : {' '.join(command)}")
    if dry_run:
        return
    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        log(f"❌ Erreur : {e}")

def detect_package_manager():
    if shutil.which("apt"):
        return "apt"
    elif shutil.which("dnf"):
        return "dnf"
    else:
        return None

def update_system(package_manager, dry_run=False):
    log(f"🔄 Mise à jour système via {package_manager}")
    if package_manager == "apt":
        cmds = [
            ["sudo", "apt", "update"],
            ["sudo", "apt", "upgrade", "-y"],
            ["sudo", "apt", "autoremove", "-y"],
            ["sudo", "apt", "clean"]
        ]
    elif package_manager == "dnf":
        cmds = [
            ["sudo", "dnf", "upgrade", "--refresh", "-y"],
            ["sudo", "dnf", "autoremove", "-y"],
            ["sudo", "dnf", "clean", "all"]
        ]
    else:
        log("❌ Aucun gestionnaire de paquets supporté trouvé.")
        return
    for cmd in cmds:
        run_command(cmd, dry_run)

def restart_services(services, dry_run=False):
    for svc in services:
        log(f"🔁 Redémarrage du service : {svc}")
        run_command(["sudo", "systemctl", "restart", svc], dry_run)

def main():
    parser = argparse.ArgumentParser(description="Script de maintenance système (Linux)")
    parser.add_argument("--dry-run", action="store_true", help="Afficher les actions sans les exécuter")
    args = parser.parse_args()

    log("=== Début de la maintenance système ===")
    pkg_mgr = detect_package_manager()
    if not pkg_mgr:
        log("❌ Aucun gestionnaire de paquets compatible trouvé (apt ou dnf).")
        return

    update_system(pkg_mgr, dry_run=args.dry_run)
    restart_services(SERVICES, dry_run=args.dry_run)
    log("✅ Maintenance terminée.")

if __name__ == "__main__":
    main()
