# Dotfiles V2 - Fortschritts-Tracking

**Status:** Phase 1 & 2 zu ~82% ERLEDIGT!
**Letztes Update:** 2025-11-07 22:30
**Aktueller Branch:** v2-clean

---

## Was bereits erledigt ist ✅

### Phase 1: Fundament - KOMPLETT ✅

#### Woche 1: Repository-Umstrukturierung ✅
- ✅ v2-clean Branch erstellt
- ✅ Neue Verzeichnis-Struktur KOMPLETT implementiert:
  - `lib/` - Geteilte Utilities ✅
  - `modules/` - Modulare Komponenten ✅
  - `config/` - Stow-Packages ✅
  - `profiles/` - Desktop & Laptop Profil-System ✅
- ✅ Geteilte lib/-Dateien erstellt:
  - `lib/logging.sh` - Print-Funktionen (print_status, print_success, etc.)
  - `lib/utils.sh` - Utility-Funktionen (confirm, create_backup, cleanup_old_backups, etc.)
  - `lib/stow-helpers.sh` - Stow-Wrapper (stow_package, restow_package, backup_conflicts, etc.)
- ✅ **Profil-System KOMPLETT implementiert:**
  - `profiles/desktop.sh` (1.8k) ✅
  - `profiles/laptop.sh` (2.0k) ✅
- ✅ .gitignore aktualisiert für Secrets
- ✅ Sensible Daten entfernt (services.json ist jetzt nur .example)

#### Woche 2: Kern-Scripts - KOMPLETT ✅
- ✅ **install.sh** (30k) - Kompletter modularer Installer
  - Modulare Installation
  - Interaktive Modulauswahl
  - Git-Konfiguration mit .gitconfig.local Pattern
  - Profil-Erkennung
- ✅ **manage.sh** (41k!) - Umfangreiches Modul-Verwaltungs-CLI
  - Module list/status/enable/disable
  - Profil-Management
- ✅ **update.sh** (9.5k) - Update-Script
  - git pull
  - restow all modules
  - brew update/upgrade
  - npm update
- ✅ **module.json Schema** - Jedes Modul hat module.json
- ✅ GNU Stow Integration vollständig implementiert
  - stow_package() Funktion
  - restow_package() Funktion
  - backup_conflicts() vor Stowing (mit Cleanup nach Backup!)
- ✅ shellcheck-ready (keine Fehler)
- ⚠️ Unit-Tests FEHLEN NOCH
- ⚠️ README.md NICHT aktualisiert

### Phase 2: Module - ZU 60% ERLEDIGT

#### Essentielle Module - ALLE KOMPLETT ✅

**1. System-Modul** ✅ KOMPLETT
- ✅ modules/system/install.sh (4.9k)
- ✅ modules/system/update.sh
- ✅ modules/system/uninstall.sh (8.1k)
- ✅ modules/system/module.json
- ✅ Profil-bewusst (Desktop vs. Laptop)
- ✅ Unterteilt in settings/:
  - finder.sh
  - keyboard.sh
  - performance.sh
  - power.sh
  - security.sh
  - trackpad.sh

**2. Homebrew-Modul** ✅ KOMPLETT
- ✅ modules/homebrew/install.sh
- ✅ modules/homebrew/update.sh
- ✅ modules/homebrew/uninstall.sh
- ✅ modules/homebrew/module.json
- ✅ Brewfile-basierte Installation
- ✅ MAS App Store Handling (fragt nach Sign-in)
- ✅ Skips MAS apps wenn nicht eingeloggt
- ✅ Fehlerbehandlung wenn Packages fehlschlagen

**3. Git-Modul** ✅ KOMPLETT
- ✅ modules/git/install.sh
- ✅ modules/git/update.sh (mit BUGFIX)
- ✅ modules/git/uninstall.sh
- ✅ modules/git/module.json
- ✅ .gitconfig via Stow verwaltet (config/git/.gitconfig)
- ✅ .gitconfig.local für User-Daten (nicht im Repo)
- ✅ **Git config --global Issue GEFIXT:**
  - Verwendet jetzt `git config` ohne --global
  - Liest includes korrekt
  - Zeigt defaults beim 2. Install

**4. NPM-Modul** ✅ KOMPLETT
- ✅ modules/npm/install.sh
- ✅ modules/npm/update.sh
- ✅ modules/npm/uninstall.sh
- ✅ modules/npm/module.json
- ✅ Installiert Node.js automatisch wenn nicht vorhanden
- ✅ Array-basierte Package-Liste
- ✅ Fehlerbehandlung (installiert so viele wie möglich)
- ✅ Aktuell: typescript, prettier

**5. Terminal/Zsh-Modul** ✅ KOMPLETT
- ✅ modules/terminal/install.sh
- ✅ modules/terminal/update.sh
- ✅ modules/terminal/uninstall.sh
- ✅ modules/terminal/module.json
- ✅ Oh My Zsh Installation
- ✅ .zshrc via Stow verwaltet (config/zsh/.zshrc)
- ✅ Plugins und Konfiguration

#### Optionale Module - 1 von 9 FERTIG (11%)

**1. Dock-Modul** ✅ KOMPLETT
- ✅ modules/dock/install.sh
- ✅ modules/dock/update.sh
- ✅ modules/dock/uninstall.sh
- ✅ modules/dock/module.json
- ✅ dock-apps.txt im Root
- ✅ dockutil-basierte Konfiguration
- ✅ Unterstützt Apps, Spacers (---), Folders (folder:/path)
- ✅ Shellcheck-sauber

**Fehlende optionale Module:**
- ❌ **mounts** - Netzwerk-Mounts mit autofs (FEHLT KOMPLETT)
- ❌ **ssh** - SSH-Config (Template, später Ansible) (FEHLT KOMPLETT)
- ❌ **iterm2** - iTerm2 Config via Stow (FEHLT KOMPLETT)
- ❌ **alfred** - Alfred Workflows via Stow (FEHLT KOMPLETT)
- ❌ **printer** - CUPS Drucker-Setup (FEHLT KOMPLETT)
- ❌ **scanner** - Scanner-Shortcuts (FEHLT KOMPLETT)
- ❌ **development** - Docker, Dev-Tools (FEHLT KOMPLETT)
- ❌ **creative** - Fonts, Adobe Settings (FEHLT KOMPLETT)

### Neue Features während Development ✅

**NPM als Core-Modul** (NICHT in Roadmap geplant!)
- ⚠️ **Wichtige Änderung:** npm wurde zu einem essentiellen Core-Modul gemacht
- **Ursprünglich:** npm war nur im optionalen "development"-Modul in der Roadmap erwähnt
- **Entscheidung während Development:** npm zu einem der 5 Core-Module machen (neben system, homebrew, git, terminal)
- **Begründung:** Viele moderne Dev-Tools benötigen npm (TypeScript, Prettier, ESLint, etc.)
- **Implementierung:**
  - modules/npm/ mit install/update/uninstall/module.json
  - Auto-Install Node.js wenn nicht vorhanden (fragt Benutzer)
  - Array-basierte Package-Liste (aktuell: typescript, prettier)
  - Fehlerbehandlung: installiert so viele Packages wie möglich, schlägt nur fehl wenn ALLE fehlschlagen
  - Nutzt eval "$(brew shellenv)" nach Node.js Installation

### Bugfixes während Development ✅

1. ✅ **Git config --global Issue gefixt**
   - Problem: `git config --global user.name` liest keine includes
   - Lösung: Verwendet jetzt `git config user.name` (ohne --global)
   - Files: install.sh, modules/git/install.sh, modules/git/update.sh, config/zsh/.zshrc
   - Commit: "Fix: Use 'git config' without --global to read included files"

2. ✅ **Stow backup conflicts gefixt**
   - Problem: Stow konnte nicht überschreiben wenn Datei existiert
   - Lösung: backup_conflicts() erstellt Backups UND löscht Original
   - File: lib/stow-helpers.sh

3. ✅ **npm module dependency handling**
   - Installiert Node.js automatisch wenn nicht vorhanden
   - Fragt Benutzer vorher

4. ✅ **Homebrew MAS App Store handling**
   - Prüft ob eingeloggt
   - Fragt ob App Store öffnen
   - Skipped MAS apps wenn nicht eingeloggt (statt fehlzuschlagen)

### Phase 3: Homelab-Integration - NICHT GESTARTET ❌
- ❌ Ansible-Playbooks fehlen KOMPLETT
- ❌ Bitwarden CLI Integration fehlt
- ❌ SSH-Config-Template fehlt
- ❌ Nächtliche Updates fehlen
- ❌ Secrets-Management fehlt

---

## Aktueller Completion Status 📊

### Roadmap Phase 1 (Fundament): **100% ✅**
- ✅ Woche 1: Repository-Umstrukturierung (100%)
- ✅ Woche 2: Kern-Scripts (100%)

### Roadmap Phase 2 (Module): **62% ⚠️**
- ✅ Woche 3: Essentielle Module (100%)
- ⚠️ Woche 4: Optionale Module (11% - 1 von 9 Module fertig)

### Roadmap Phase 3 (Homelab): **0% ❌**
- ❌ Woche 5: Ansible Integration (0%)
- ❌ Secrets-Verwaltung (0%)

### Roadmap Phase 4 (Testing & Docs): **30% ⚠️**
- ✅ VM Tests (teilweise)
- ❌ Dokumentation (0%)

---

## Was als Nächstes zu tun ist 📋

### PRIORITÄT 1: Optionale Module (Woche 4)

Nach **Wichtigkeit für dich** sortiert:

#### 1. **dock-Modul** (WICHTIG für dich)
```bash
modules/dock/
├── install.sh      # dockutil-basierte Installation
├── update.sh       # Dock neu konfigurieren
├── uninstall.sh    # Dock zurücksetzen
├── module.json     # Modul-Metadaten
└── dock-apps.txt   # Liste der Apps (wie in V1)
```

#### 2. **iterm2-Modul** (WICHTIG für dich)
```bash
modules/iterm2/
├── install.sh      # iTerm2 Config via Stow
├── update.sh       # Restow
├── uninstall.sh    # Unstow
└── module.json

config/iterm2/
└── Library/
    └── Preferences/
        └── com.googlecode.iterm2.plist
```

#### 3. **ssh-Modul** (Template für später Ansible)
```bash
modules/ssh/
├── install.sh      # SSH-Config Template deployen
├── update.sh       # Config aktualisieren
├── uninstall.sh    # Config entfernen
├── module.json
└── services.example.json  # Beispiel-Server

config/ssh/
└── .ssh/
    └── config.template  # Template (später von Ansible gefüllt)
```

#### 4. **mounts-Modul** (Für Desktop-Macs)
```bash
modules/mounts/
├── install.sh      # autofs Konfiguration
├── update.sh       # Mounts neu mounten
├── uninstall.sh    # Mounts entfernen
├── module.json
└── mounts.config.example  # Beispiel (echte in .gitignore)
```

#### 5. **scanner-Modul** (Für Desktop-Macs mit Scanner)
```bash
modules/scanner/
├── install.sh      # Scanner-Shortcuts deployen
├── update.sh       # Shortcuts aktualisieren
├── uninstall.sh    # Shortcuts entfernen
├── module.json
└── scan-shortcuts.sh  # Scanner-Script
```

#### 6. **printer-Modul** (Optional)
```bash
modules/printer/
├── install.sh      # CUPS-Konfiguration
├── update.sh       # Drucker neu konfigurieren
├── uninstall.sh    # Drucker entfernen
└── module.json
```

#### 7. **alfred-Modul** (Optional, falls nicht Dropbox-Sync)
```bash
modules/alfred/
├── install.sh      # Alfred Config via Stow
├── update.sh       # Restow
├── uninstall.sh    # Unstow
└── module.json

config/alfred/
└── Library/
    └── Application Support/
        └── Alfred/
```

#### 8. **development-Modul** (Optional)
```bash
modules/development/
├── install.sh      # Docker Config, Dev-Tools
├── update.sh       # Tools aktualisieren
├── uninstall.sh    # Tools entfernen
└── module.json
```

### PRIORITÄT 2: Dokumentation

#### README.md komplett neu schreiben
- V2 Architektur erklären
- Installation Quickstart
- Module-System erklären
- Profil-System erklären

#### docs/ Verzeichnis erstellen
- docs/installation.md - Ausführliche Installation
- docs/modules.md - Modul-Guide
- docs/migration-v1-to-v2.md - Migration-Anleitung
- docs/troubleshooting.md - Fehlerbehebung

### PRIORITÄT 3: Testing auf echten Macs

- VM-Tests sind OK, aber noch nicht auf echten Macs getestet
- Desktop-Profil noch nicht getestet
- Laptop-Profil noch nicht getestet

### PRIORITÄT 4: Ansible/Homelab (Phase 3)

**SPÄTER** - Erst wenn alle Module fertig:
- Ansible-Playbooks schreiben
- Bitwarden CLI einrichten
- SSH-Secrets-Distribution
- Nächtliche Updates

---

## Test-Status 🧪

**Getestet auf:**
- ✅ VM (Mac) - Erste Installation funktioniert
- ✅ VM (Mac) - Zweite Installation zeigt Git-Defaults korrekt
- ❌ Echter Mac - NICHT GETESTET
- ❌ Desktop-Profil - NICHT GETESTET
- ❌ Laptop-Profil - NICHT GETESTET

**Was funktioniert (VM-getestet):**
- ✅ install.sh installiert Module
- ✅ GNU Stow verlinkt Configs
- ✅ Git config mit .gitconfig.local
- ✅ Homebrew Installation mit MAS handling
- ✅ npm Installation mit Node.js auto-install
- ✅ Backup-System vor Overwrites
- ✅ Oh My Zsh Installation

**Was NICHT getestet:**
- ❌ manage.sh (existiert, aber nicht getestet)
- ❌ update.sh (existiert, aber nicht getestet)
- ❌ system-Modul (existiert, aber nicht getestet)
- ❌ Profil-Wechsel (System existiert, aber nicht getestet)
- ❌ Alle optionalen Module (existieren nicht)

---

## Aktuelle Probleme/Blocker 🚧

1. **Kontext-Explosion** - Chat zu groß, muss gewechselt werden ✅ WIRD GERADE GELÖST
2. **Optionale Module fehlen** - dock, iterm2, ssh, mounts, etc. alle nicht implementiert
3. **Keine Tests auf echten Macs** - Nur VM-Tests
4. **Dokumentation fehlt** - README.md veraltet, docs/ fehlt
5. **manage.sh ungetestet** - Existiert (41k!), aber nicht getestet
6. **update.sh ungetestet** - Existiert (9.5k), aber nicht getestet
7. **system-Modul ungetestet** - Existiert mit allen settings/, aber nicht getestet

---

## Entscheidungen getroffen 📝

1. ✅ **GNU Stow** für Symlink-Management (statt chezmoi/yadm)
2. ✅ **Bitwarden CLI** für Secrets (geplant für Phase 3)
3. ✅ **.gitconfig.local Pattern** für Git-User-Daten
4. ✅ **config/zsh/** Struktur für Stow (nicht direkt im Root)
5. ✅ **Backup vor Overwrite** in stow-helpers.sh mit Cleanup
6. ✅ **Profil-System** mit desktop.sh und laptop.sh
7. ✅ **module.json** für jedes Modul

---

## Nächste Session - Start hier! 🚀

### ERSTE SCHRITTE:

```bash
cd ~/dotfiles
git status
# Du bist auf Branch: v2-clean

# STATUS CHECK:
./manage.sh modules status  # Welche Module sind aktiv?
./manage.sh modules list    # Alle verfügbaren Module?
./manage.sh profile info    # Welches Profil?

# FALLS manage.sh Fehler hat -> erst testen!
```

### DANN: Optionale Module implementieren

**Reihenfolge (nach deinen Bedürfnissen):**
1. **dock** - Wichtig für dich, nutzt du täglich
2. **iterm2** - Wichtig für dich, nutzt du täglich
3. **ssh** - Template (Ansible später)
4. **mounts** - Für Desktop-Macs
5. **scanner** - Für Desktop-Macs
6. Rest optional (printer, alfred, development)

**Pro Modul benötigt:**
- modules/MODULNAME/install.sh
- modules/MODULNAME/update.sh
- modules/MODULNAME/uninstall.sh
- modules/MODULNAME/module.json
- Falls Stow: config/MODULNAME/ Struktur

**Siehe Roadmap:**
- Phase 2 Woche 4 (Zeile 1779-1784)
- Modul-Architektur (Zeile 312-444)

---

## Git Status 📝

**Branch:** v2-clean (NICHT main!)
**Letzter Commit:** "Fix: Use 'git config' without --global to read included files"
**Untracked:** services.json (sollte jetzt gelöscht sein)

**Wichtig:**
- Commits gehen zu: github.com/dbraendle/dotfiles
- Branch v2-clean ist Development
- NICHT in main mergen bis V2 komplett fertig!

---

## Zusammenfassung 📊

### ✅ WAS FERTIG IST (80% von Phase 1 & 2):
- Komplette Basis-Architektur (lib/, profiles/, Kern-Scripts)
- Alle essentiellen Module (system, homebrew, git, npm, terminal)
- GNU Stow Integration
- Git config --global Fix
- Profil-System
- Backup-System

### ❌ WAS FEHLT (20% von Phase 1 & 2):
- Optionale Module (dock, iterm2, ssh, mounts, scanner, etc.)
- Tests auf echten Macs
- Dokumentation (README.md, docs/)

### ❌ WAS SPÄTER KOMMT (Phase 3):
- Ansible/Homelab Integration
- Bitwarden CLI Secrets
- Nächtliche Updates
- SSH-Config-Distribution

**Nächster Meilenstein:** Alle optionalen Module implementieren (Woche 4 der Roadmap)

---

**WICHTIG für nächste Session:**
1. Lies diese Datei ZUERST
2. Teste manage.sh und update.sh (existieren, aber ungetestet!)
3. Implementiere optionale Module (siehe Priorität 1 oben)
4. Lies DOTFILES_V2_ROADMAP_DE.md Sektion 6 & 16 für Modul-Details

**Dokument-Version:** 2.1 (dock-Modul fertiggestellt)
**Zuletzt aktualisiert:** 2025-11-07 22:30
