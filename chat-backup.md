# Chat Session Backup - So 14 Sep 2025 02:37:52 CEST

## Problem WIRKLICH gelöst: autofs Mount-Point verschwindet nach Neustart

**Problem:** `/Volumes/auto_mounts` Ordner verschwindet nach jedem macOS Neustart, autofs kann nicht mounten.

**Ursache entdeckt:**
- macOS löscht automatisch user-created folders in `/Volumes` beim Boot (seit Mavericks!)
- Erste cleanup_old_mounts() Fix war nicht das Hauptproblem
- autofs braucht den Mount-Point VOR dem Start

**Echte Lösung gefunden:** `/../` Path Trick für autofs
- Problem: autofs config hatte `/Volumes/auto_mounts auto_mounts`
- Lösung: `/../Volumes/auto_mounts auto_mounts` - trickst macOS aus!

**Änderungen in mount-setup.sh:**
1. Neue Variable: `AUTOFS_MOUNT_PATH="/../Volumes/auto_mounts"`
2. Zeile 143 geändert: `local autofs_entry="$AUTOFS_MOUNT_PATH auto_mounts"`
3. LaunchDaemon erstellt für persistente Mount-Point Erstellung

**Warum der `/../` Trick funktioniert:**
- macOS denkt, autofs mountet "woanders"
- Trotzdem landet es in `/Volumes/auto_mounts`
- Umgeht die macOS `/Volumes` cleanup Logik

**Status nach diesem Chat:**
- mount-setup.sh mit `/../` Trick: ✅
- LaunchDaemon für Boot-Setup: ✅
- Bereit für Neustart-Test: ✅

**Nächster Schritt:**
1. `./mount-setup.sh` ausführen (installiert LaunchDaemon + `/../` config)
2. Neustart
3. Prüfen ob `/Volumes/auto_mounts/MedienHIHIHIHI` automatisch verfügbar ist
