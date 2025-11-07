# Dotfiles V2 - Kompletter Fahrplan & Architektur

> **Version:** 2.0.0
> **Datum:** 2025-01-07
> **Autor:** Analyse & Empfehlungen von Claude (Sonnet 4.5)
> **Status:** Planungsphase

---

## Inhaltsverzeichnis

1. [Executive Summary](#1-executive-summary)
2. [Probleme mit V1](#2-probleme-mit-v1)
3. [V2 Vision & Ziele](#3-v2-vision--ziele)
4. [Architektur-Überblick](#4-architektur-überblick)
5. [GNU Stow Integration](#5-gnu-stow-integration)
6. [Modulares System-Design](#6-modulares-system-design)
7. [Profil-System](#7-profil-system)
8. [Homelab Integration](#8-homelab-integration)
9. [SSH & Secrets Management](#9-ssh--secrets-management)
10. [Installations-Ablauf](#10-installations-ablauf)
11. [Update-Strategie](#11-update-strategie)
12. [Sicherheitsverbesserungen](#12-sicherheitsverbesserungen)
13. [Datei-Struktur](#13-datei-struktur)
14. [Tools & Technologien](#14-tools--technologien)
15. [Migrationspfad](#15-migrationspfad)
16. [Implementierungs-Roadmap](#16-implementierungs-roadmap)
17. [Zusammenfassung](#17-zusammenfassung)

---

## 1. Executive Summary

**Aktueller Zustand:** V1 Dotfiles sind funktional, aber chaotisch - 3000+ Zeilen Shell-Scripts mit Sicherheitsproblemen, Code-Duplikaten, veralteter Dokumentation und wachsender technischer Schuld.

**Ziel:** Transformation in ein professionelles, modulares, Homelab-integriertes Dotfiles-System, das:
- **GNU Stow** für Symlink-basiertes Config-Management nutzt (kein Kopieren mehr)
- **Modulare Installation** via interaktivem CLI-Menü bietet
- Mit **Ansible** für automatische nächtliche Updates auf allen Macs integriert
- **Desktop vs. Laptop Profile** für gerätespezifische Einstellungen trennt
- **Ordentliches Secrets-Management** implementiert (Bitwarden CLI oder Ansible Vault)
- **Maximale Abdeckung** behält - wenn eine Einstellung automatisierbar ist, wird sie es
- **VS Code Settings** ausschließt (via GitHub Settings Sync verwaltet)

**Kernänderung:** Von "Configs bei Installation kopieren" zu "alles verlinken + Ansible-Orchestrierung"

**Timeline:** 4-6 Wochen für vollständige V2-Implementierung

---

## 2. Probleme mit V1

### Kritische Probleme

**Sicherheit:**
- Echte Server-IPs/Benutzernamen im Repository committed (`ssh/services.json`)
- Passwort nach Ruhezustand auf allen Geräten deaktiviert (Zeile `macos-settings.sh:252`)
- Falsche SSH-Config-Berechtigungen (644 statt 600)
- Unverifizierte Remote-Downloads (`curl | sudo tee`)
- CUPS Web-Interface aktiviert ohne Dokumentation

**Code-Qualität:**
- 6 Scripts duplizieren Farbdefinitionen und Print-Funktionen
- 1012-Zeilen `ssh-setup.sh` mit komplexem Menüsystem
- `npm-install.sh` nutzt `return 1` außerhalb von Funktionen (sollte `exit 1` sein)
- Hardcodierte Pfade (`~/Dev/dotfiles`) brechen, wenn Repo verschoben wird
- System-Command-Aliase (`ls→eza`, `cat→bat`) brechen Scripts

**Architektur:**
- Zwei parallele SSH-Systeme (ssh-wunderbar + Legacy-Script)
- Config-Dateien werden kopiert statt verlinkt (Änderungen nicht getrackt)
- Keine automatische Synchronisation zwischen Maschinen
- Brewfile hat doppelte Einträge (`cask "stats"` zweimal)
- Gemischte Deutsch/Englisch-Dokumentation

**Wartung:**
- Dokumentation behauptet Features, die nicht implementiert sind (`--headless`, `--ssh-only`)
- Verwaiste Dateien (`temp-apps-list.md`, `true/`-Verzeichnis)
- Überall auskommentierter Code
- Kein Shell-Linting (shellcheck)
- Keine Test-Infrastruktur

### Was gut funktioniert (Behalten!)

✅ **Modulares Design** - Scripts können einzeln ausgeführt werden
✅ **Idempotenz** - sicher mehrfach ausführbar
✅ **Interaktive Prompts** - gute UX
✅ **Umfassende Abdeckung** - handhabt System-Settings, Packages, Terminal, Git, Dock, Mounts
✅ **Intelligente Automatisierung** - erkennt Apple Silicon vs. Intel, bietet Fallbacks
✅ **Backup-Erstellung** - vor Änderungen

---

## 3. V2 Vision & Ziele

### Kernprinzipien

1. **Alles Verlinken** - GNU Stow verwaltet alle Dotfiles, Änderungen sofort reflektiert
2. **Modular by Design** - Jedes Feature ist ein optionales Modul
3. **Homelab-Orchestriert** - Ansible triggert nächtliche Updates, verwaltet Secrets
4. **Profil-Basiert** - Desktop vs. Laptop haben unterschiedliche Sicherheits-/Energie-Einstellungen
5. **Security-First** - Keine Secrets im Repo, korrekte Berechtigungen, verifizierte Downloads
6. **Maximale Abdeckung** - Automatisiere alles Mögliche (Alfred, iTerm2, Dock, Printing, etc.)
7. **Single Source of Truth** - GitHub Repo + Homelab Secrets Vault
8. **Zero Manual Work** - Neuer Mac: Repo klonen, install ausführen, 3 Fragen beantworten, fertig

### Ziel-Workflow

**Ersteinrichtung (Frischer Mac):**
```bash
git clone https://github.com/dbraendle/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
# Interaktives Menü erscheint:
#   [1] Vollständige Installation (Desktop-Profil)
#   [2] Vollständige Installation (Laptop-Profil)
#   [3] Benutzerdefiniert - Module auswählen
# Option wählen, Git-Benutzerdaten eingeben, in 30 Min fertig
```

**Tägliche Nutzung:**
```bash
# Config-Datei direkt in ~/dotfiles/ bearbeiten
vim ~/dotfiles/zsh/.zshrc
# Änderungen sofort aktiv (verlinkt)
git commit -am "Update zsh config"
git push
# Homelab Ansible zieht Änderungen nachts auf alle Macs
```

**Modul-Verwaltung:**
```bash
./manage.sh --enable module-name   # Modul aktivieren
./manage.sh --disable module-name  # Modul deaktivieren
./manage.sh --status               # Aktive Module anzeigen
```

---

## 4. Architektur-Überblick

### High-Level Design

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                         │
│              github.com/dbraendle/dotfiles                   │
│                                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐           │
│  │  Config    │  │  Module    │  │  Scripts   │           │
│  │  Dateien   │  │  (opt-in)  │  │  (core)    │           │
│  │  (Stow)    │  │            │  │            │           │
│  └────────────┘  └────────────┘  └────────────┘           │
└─────────────────────────────────────────────────────────────┘
                           ▲
                           │ git pull (nächtlich via Ansible)
                           │
┌──────────────────────────┴──────────────────────────────────┐
│                    Homelab Ansible                           │
│                                                              │
│  ┌────────────────┐  ┌─────────────────┐                   │
│  │  Secrets Vault │  │  Update Playbook│                   │
│  │  (Bitwarden/   │  │  - brew update  │                   │
│  │   Ansible Vault)│  │  - git pull     │                   │
│  │                │  │  - stow restow  │                   │
│  └────────────────┘  └─────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
   ┌──────────┐      ┌──────────┐      ┌──────────┐
   │  Mac     │      │  Mac     │      │  Mac     │
   │  Mini    │      │  Book    │      │  Book    │
   │ (Desktop)│      │ (Laptop) │      │(Desktop) │
   └──────────┘      └──────────┘      └──────────┘
        │                 │                 │
        └─────────────────┴─────────────────┘
                Symlinks zu ~/dotfiles/* (via Stow)
```

### Komponenten-Aufteilung

**1. GitHub Repository (Öffentlich)**
- Quellcode für alle Scripts
- Config-Datei-Templates (keine Secrets)
- Dokumentation
- Brewfile mit Package-Definitionen
- Modul-Definitionen

**2. Homelab Ansible**
- Zentrale Orchestrierungs-Server
- Secrets-Speicherung (Bitwarden CLI oder Ansible Vault)
- Nächtliche Update-Playbooks
- SSH-Config-Distribution
- Security-Patch-Management

**3. Individuelle Macs**
- Klon des Dotfiles-Repos in `~/dotfiles`
- GNU Stow Symlinks: `~/.zshrc` → `~/dotfiles/zsh/.zshrc`
- Aktive Module getrackt in `~/.dotfiles-modules`
- Profil gespeichert in `~/.dotfiles-profile` (`desktop` oder `laptop`)

---

## 5. GNU Stow Integration

### Was ist GNU Stow?

GNU Stow ist ein Symlink-Farm-Manager. Es erstellt Symlinks von einem Quell-Verzeichnisbaum zu einem Ziel-Verzeichnisbaum.

**Traditioneller Ansatz (V1):**
```bash
# Dotfiles in Home-Verzeichnis kopiert
cp ~/dotfiles/.zshrc ~/.zshrc
# Problem: Änderungen in ~/.zshrc NICHT in Git getrackt
# Muss manuell zurück ins Dotfiles-Repo kopiert werden
```

**GNU Stow Ansatz (V2):**
```bash
# Dotfiles ins Home-Verzeichnis verlinkt
stow -d ~/dotfiles -t ~ zsh
# Erstellt: ~/.zshrc → ~/dotfiles/zsh/.zshrc
# Änderungen in ~/.zshrc automatisch im Git-Repo
```

### Verzeichnisstruktur für Stow

```
~/dotfiles/
├── zsh/
│   ├── .zshrc          # Wird zu ~/.zshrc
│   └── .zshenv         # Wird zu ~/.zshenv
├── git/
│   └── .gitconfig      # Wird zu ~/.gitconfig
├── ssh/
│   └── .ssh/
│       └── config      # Wird zu ~/.ssh/config
├── vscode/             # OPTIONAL - nur wenn nicht GitHub Sync
│   └── .config/
│       └── Code/
│           └── User/
│               └── settings.json
├── alfred/
│   └── Library/
│       └── Application Support/
│           └── Alfred/
│               └── Alfred.alfredpreferences/
└── iterm2/
    └── .config/
        └── iterm2/
            └── com.googlecode.iterm2.plist
```

### Stow Workflow

**Ersteinrichtung:**
```bash
# Stow via Homebrew installieren
brew install stow

# Alle Packages stowen
cd ~/dotfiles
stow -t ~ zsh git ssh alfred iterm2

# Symlinks verifizieren
ls -la ~ | grep "\->"
# Ausgabe:
# .zshrc -> dotfiles/zsh/.zshrc
# .gitconfig -> dotfiles/git/.gitconfig
```

**Änderungen vornehmen:**
```bash
# Datei direkt bearbeiten (Symlink löst zu dotfiles auf)
vim ~/.zshrc
# Oder im Repo bearbeiten
vim ~/dotfiles/zsh/.zshrc
# Beides ist dieselbe Datei!

# Änderungen committen
cd ~/dotfiles
git add zsh/.zshrc
git commit -m "Update zsh aliases"
git push
```

**Restowing (z.B. nach git pull):**
```bash
cd ~/dotfiles
stow -R -t ~ zsh  # Restow um neue Dateien aufzunehmen
```

### Vorteile

✅ **Single Source of Truth** - Nur eine Kopie jeder Config-Datei
✅ **Sofortiger Sync** - Änderungen sofort reflektiert
✅ **Versionskontrolle** - Alle Änderungen in Git getrackt
✅ **Einfaches Rollback** - `git revert` funktioniert auf Live-Configs
✅ **Multi-Maschinen-Sync** - Git pull + restow = sofortiger Sync
✅ **Selektives Deployment** - Stowe nur was du brauchst

### Einschränkungen

⚠️ **Bestehende Dateien:** Stow verweigert Überschreiben. Muss vorher gesichert/entfernt werden.
⚠️ **Verzeichnisstruktur:** Muss exakt zu Zielpfaden passen.
⚠️ **Geschützte Dateien:** Manche macOS-Dateien benötigen spezifische Berechtigungen.
⚠️ **Templating:** Git-User-Platzhalter benötigen Vorverarbeitung vor dem Stowen.

---

## 6. Modulares System-Design

### Modul-Architektur

Jedes Modul ist eigenständig mit:
- Config-Dateien (falls zutreffend)
- Installations-Script (`install.sh`)
- Deinstallations-Script (`uninstall.sh`)
- Abhängigkeitsliste
- Dokumentation

### Core-Module (Immer installiert)

**1. system** - macOS System-Einstellungen
- Finder, Keyboard, Trackpad, Screenshots
- Performance-Optimierungen
- Sicherheits-Baseline (Firewall, etc.)
- Profil-bewusst (Desktop vs. Laptop Unterschiede)

**2. homebrew** - Paket-Manager
- Installiert Homebrew (Apple Silicon / Intel Erkennung)
- Verarbeitet Brewfile
- Richtet Auto-Cleanup ein

**3. terminal** - Shell-Konfiguration
- Oh My Zsh Installation
- Zsh-Plugins (autosuggestions, syntax highlighting)
- `.zshrc` mit Aliases und Funktionen
- Stow-verwaltet

**4. git** - Versionskontrolle
- `.gitconfig` mit Aliases und Einstellungen
- Interaktives User/Email-Setup
- Credential-Helper (macOS Keychain)
- Stow-verwaltet

### Optionale Module

**5. dock** - Dock-Verwaltung
- `dockutil` für automatisiertes Dock-Layout
- Lädt aus `dock-apps.txt`
- Spacer und Ordner

**6. mounts** - Netzwerk-Mounts
- autofs-Konfiguration für NFS/SMB
- On-Demand Mounting
- Lädt aus `mounts.config`
- LaunchDaemon-Verwaltung

**7. ssh** - SSH-Konfiguration
- SSH-Config-Generierung
- Alias-Erstellung (`ssh myserver` → `ssh user@192.168.1.10`)
- Verwaltet vom Homelab (Secrets von Ansible)
- Public-Key-Distribution via Ansible

**8. printer** - Drucker-Setup
- CUPS-Konfiguration
- Drucker-Auto-Discovery
- Standard-Drucker-Setup
- Optional (manuelles Opt-in)

**9. iterm2** - iTerm2-Konfiguration
- Farbschemata
- Profile
- Hotkeys
- Stow-verwaltet

**10. alfred** - Alfred Workflows
- Benutzerdefinierte Workflows
- Hotkeys
- Einstellungen
- Stow-verwaltet (falls Dropbox-Sync verwendet, überspringen)

**11. development** - Entwicklungs-Tools
- Docker-Daemon-Konfiguration
- Node-Version-Manager-Setup
- Benutzerdefinierte Dev-Aliases
- Projekt-Templates

**12. creative** - Kreativ-Tools
- Adobe-Einstellungen (falls zutreffend)
- Font-Installation
- Farbprofile

**13. scanner** - Scanner-Integration
- Scanner-Shortcuts (`.scan-shortcuts.sh`)
- Benötigt Hostname-Variable für Scan-Server
- Optional

### Modul-Manifest

Jedes Modul hat eine `module.json`:

```json
{
  "name": "dock",
  "description": "Automatisierte Dock-Konfiguration",
  "category": "optional",
  "dependencies": ["homebrew"],
  "conflicts": [],
  "stow_packages": [],
  "scripts": {
    "install": "modules/dock/install.sh",
    "uninstall": "modules/dock/uninstall.sh",
    "update": "modules/dock/update.sh"
  },
  "profiles": ["desktop", "laptop"],
  "settings": {
    "dock_apps_file": "config/dock-apps.txt"
  }
}
```

### Modul-CLI

```bash
# Interaktives Menü
./install.sh
# > Module auswählen:
# > [x] core (system, homebrew, terminal, git)
# > [ ] dock
# > [ ] mounts
# > [ ] ssh (vom Homelab verwaltet)
# > ...

# Direkte Modul-Verwaltung
./manage.sh modules list                  # Alle Module auflisten
./manage.sh modules enable dock           # Dock-Modul aktivieren
./manage.sh modules disable dock          # Dock-Modul deaktivieren
./manage.sh modules status                # Aktive Module anzeigen
./manage.sh modules install dock          # Spezifisches Modul installieren
./manage.sh modules uninstall dock        # Spezifisches Modul deinstallieren
```

---

## 7. Profil-System

### Profil-Typen

**Desktop-Profil:**
- **Kein Passwort nach Ruhezustand** (Komfort, stationäre Maschine)
- **Mac schläft nie** (Lang laufende Tasks)
- **Alle Module verfügbar** (mounts, printer, scanner)
- **Performance-Optimierungen**

**Laptop-Profil:**
- **Passwort nach Ruhezustand AKTIVIERT** (Sicherheit, portabel)
- **Batterie-Optimierungen** (Display-Ruhezustand 10min)
- **Reduzierte Hintergrund-Prozesse**
- **Optionale Module** (Drucker, Scanner überspringen)

### Profil-Erkennung

**Automatisch (Empfohlen):**
```bash
# Erkennt ob MacBook (portabel) oder Mac mini/iMac (desktop)
if system_profiler SPHardwareDataType | grep -q "MacBook"; then
    PROFILE="laptop"
else
    PROFILE="desktop"
fi
```

**Manuelles Override:**
```bash
./install.sh --profile desktop
./install.sh --profile laptop
```

**Profil später ändern:**
```bash
./manage.sh profile set laptop
# Wendet profil-spezifische Einstellungen erneut an
```

### Profil-Spezifische Einstellungen

**Datei:** `profiles/desktop.sh`
```bash
# Desktop-spezifische macOS-Einstellungen
export ENABLE_PASSWORD_AFTER_SLEEP=false
export DISPLAY_SLEEP_MINUTES=15
export SYSTEM_SLEEP_MINUTES=0
export ENABLE_PRINTER_MODULE=true
export ENABLE_SCANNER_MODULE=true
export ENABLE_NETWORK_MOUNTS=true
```

**Datei:** `profiles/laptop.sh`
```bash
# Laptop-spezifische macOS-Einstellungen
export ENABLE_PASSWORD_AFTER_SLEEP=true
export DISPLAY_SLEEP_MINUTES=10
export SYSTEM_SLEEP_MINUTES=30
export ENABLE_PRINTER_MODULE=false  # Optional, Benutzer fragen
export ENABLE_SCANNER_MODULE=false
export ENABLE_NETWORK_MOUNTS=true   # Nützlich im Home-WLAN
```

### Profil-Speicherung

```bash
# Nach Installation wird Profil lokal gespeichert
echo "laptop" > ~/.dotfiles-profile

# Scripts laden Profil bei jedem Lauf
PROFILE=$(cat ~/.dotfiles-profile)
source "$(dirname "$0")/profiles/${PROFILE}.sh"
```

---

## 8. Homelab Integration

### Architektur

**Homelab-Verantwortlichkeiten:**
1. **Automatisierte Updates** - Nächtliches Ansible-Playbook läuft auf allen Macs
2. **Secrets-Distribution** - SSH-Keys, API-Tokens, Zertifikate
3. **Zentralisiertes Logging** - Update-Erfolg/-Fehler-Tracking
4. **Konfigurations-Durchsetzung** - Sicherstellen, dass Dotfiles aktuell sind
5. **Security-Patching** - Minor-OS-Updates (nicht Major-Versionen)

### Ansible Playbook Struktur

```
~/homelab/ansible/
├── inventory/
│   ├── hosts.yml          # Alle Mac-Hosts
│   └── group_vars/
│       └── macs.yml       # Mac-spezifische Variablen
├── playbooks/
│   ├── mac-update.yml     # Nächtliches Update-Playbook
│   ├── mac-setup.yml      # Ersteinrichtung (führt install.sh aus)
│   └── mac-secrets.yml    # Secrets-Distribution
├── roles/
│   ├── dotfiles/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── git-pull.yml
│   │   │   ├── stow-restow.yml
│   │   │   └── homebrew-update.yml
│   │   └── templates/
│   │       └── ssh_config.j2
│   ├── secrets/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── ssh-keys.yml
│   │   │   └── certificates.yml
│   │   └── vars/
│   │       └── main.yml    # Verschlüsselt mit ansible-vault
│   └── updates/
│       ├── tasks/
│       │   ├── main.yml
│       │   ├── macos-minor-updates.yml
│       │   └── homebrew-updates.yml
└── ansible.cfg
```

### Nächtliches Update-Playbook

**Datei:** `playbooks/mac-update.yml`
```yaml
---
- name: Nächtliche Mac Dotfiles & Package Updates
  hosts: macs
  become: no
  vars:
    dotfiles_path: "{{ ansible_env.HOME }}/dotfiles"

  tasks:
    - name: Prüfe ob Dotfiles-Repo existiert
      stat:
        path: "{{ dotfiles_path }}"
      register: dotfiles_repo

    - name: Ziehe neueste Dotfiles von GitHub
      git:
        repo: "https://github.com/dbraendle/dotfiles.git"
        dest: "{{ dotfiles_path }}"
        update: yes
        force: no
      when: dotfiles_repo.stat.exists

    - name: Restow alle aktiven Module
      shell: |
        cd {{ dotfiles_path }}
        for module in $(cat ~/.dotfiles-modules); do
          stow -R -t ~ "$module"
        done
      args:
        executable: /bin/zsh

    - name: Aktualisiere Homebrew-Packages
      homebrew:
        update_homebrew: yes
        upgrade_all: yes
      ignore_errors: yes

    - name: Bereinige Homebrew
      shell: brew cleanup && brew autoremove
      args:
        executable: /bin/zsh

    - name: Aktualisiere npm Global-Packages
      npm:
        name: "*"
        global: yes
        state: latest
      ignore_errors: yes

    - name: Aktualisiere Oh My Zsh
      shell: |
        cd ~/.oh-my-zsh
        git pull --rebase --autostash
      args:
        executable: /bin/zsh
      ignore_errors: yes

    - name: Prüfe auf macOS Minor-Updates
      shell: softwareupdate --list 2>&1 | grep -v "No new software available"
      register: macos_updates
      ignore_errors: yes
      changed_when: false

    - name: Installiere macOS Minor-Updates (nur Security)
      shell: softwareupdate --install --no-scan --agree-to-license --recommended
      when: macos_updates.stdout != ""
      become: yes

    - name: Logge Update-Zeitstempel
      shell: echo "$(date): Dotfiles erfolgreich aktualisiert" >> ~/.dotfiles-update.log
```

### Secrets-Distribution

**Datei:** `playbooks/mac-secrets.yml`
```yaml
---
- name: Verteile SSH-Keys und Secrets
  hosts: macs
  become: no
  vars_files:
    - ../roles/secrets/vars/main.yml  # ansible-vault verschlüsselt

  tasks:
    - name: Stelle sicher dass .ssh-Verzeichnis existiert
      file:
        path: "{{ ansible_env.HOME }}/.ssh"
        state: directory
        mode: '0700'

    - name: Deploye SSH Private Keys
      copy:
        content: "{{ item.private_key }}"
        dest: "{{ ansible_env.HOME }}/.ssh/{{ item.name }}"
        mode: '0600'
      loop: "{{ ssh_keys }}"
      no_log: yes

    - name: Deploye SSH Public Keys
      copy:
        content: "{{ item.public_key }}"
        dest: "{{ ansible_env.HOME }}/.ssh/{{ item.name }}.pub"
        mode: '0644'
      loop: "{{ ssh_keys }}"

    - name: Generiere SSH-Config aus Template
      template:
        src: ../roles/secrets/templates/ssh_config.j2
        dest: "{{ ansible_env.HOME }}/.ssh/config"
        mode: '0600'

    - name: Füge SSH-Keys zum Agent hinzu
      shell: |
        eval "$(ssh-agent -s)"
        ssh-add {{ ansible_env.HOME }}/.ssh/{{ item.name }}
      loop: "{{ ssh_keys }}"
      no_log: yes
```

### Ansible Inventory

**Datei:** `inventory/hosts.yml`
```yaml
all:
  children:
    macs:
      hosts:
        mac-mini:
          ansible_host: 192.168.178.50
          ansible_user: db
          profile: desktop
        macbook-pro:
          ansible_host: 192.168.178.51
          ansible_user: db
          profile: laptop
        macbook-air:
          ansible_host: 192.168.178.52
          ansible_user: db
          profile: desktop  # Umfunktioniert als Desktop
```

### Ansible Cron Job

**Auf Homelab-Server:**
```bash
# Läuft nächtlich um 3 Uhr
0 3 * * * cd ~/homelab/ansible && ansible-playbook playbooks/mac-update.yml >> /var/log/ansible-mac-updates.log 2>&1
```

### Vorteile

✅ **Alle Macs bleiben synchron** - Änderungen in GitHub propagieren nächtlich
✅ **Security-Patches** - Minor-Updates automatisch angewendet
✅ **Zentralisierte Secrets** - Keine SSH-Keys im Dotfiles-Repo
✅ **Audit-Trail** - Ansible loggt alle Änderungen
✅ **Rollback-Fähigkeit** - Ansible kann zu vorherigem Zustand zurückkehren

---

## 9. SSH & Secrets Management

### Problem mit V1

- `ssh/services.json` enthält echte Server-IPs/User (Sicherheitsrisiko)
- SSH-Keys lokal pro Mac verwaltet (inkonsistent)
- Keine zentrale Autorität für Key-Rotation
- ssh-wunderbar nützlich, aber redundant mit Homelab

### V2-Ansatz: Ansible-Verwaltetes SSH

**Secrets-Speicher-Optionen:**

**Option A: Bitwarden CLI (Empfohlen für dich)**

**Vorteile:**
- Nutzt bereits Bitwarden (Desktop + MAS App)
- Offizielles CLI-Tool: `brew install bitwarden-cli`
- Sichere Item-Speicherung mit Verschlüsselung
- Einfache Integration mit Ansible
- Kann SSH-Keys, API-Tokens, Passwörter speichern
- Von jedem Gerät zugänglich

**Nachteile:**
- Benötigt Internet für erste Auth (danach gecacht)
- Abo für manche Features nötig (hast du vermutlich)

**Implementierung:**
```yaml
# Ansible-Playbook nutzt Bitwarden CLI
- name: Hole SSH-Key von Bitwarden
  shell: bw get item "github-ssh-key" --session {{ bw_session }} | jq -r '.notes'
  register: github_key
  no_log: yes

- name: Deploye SSH-Key
  copy:
    content: "{{ github_key.stdout }}"
    dest: "~/.ssh/id_ed25519"
    mode: '0600'
```

**Setup:**
```bash
# Auf Homelab-Server
brew install bitwarden-cli
bw login deine-email@example.com
bw unlock  # Session-Token erhalten
export BW_SESSION="session-token"

# SSH-Keys in Bitwarden als Secure Notes speichern
bw create item '{
  "type": 2,
  "name": "github-ssh-key",
  "notes": "-----BEGIN OPENSSH PRIVATE KEY-----\n...",
  "secureNote": {"type": 0}
}'
```

**Option B: Ansible Vault**

**Vorteile:**
- In Ansible eingebaut
- Keine externen Abhängigkeiten
- Verschlüsselt mit Master-Passwort
- Einfache Key-Value-Speicherung

**Nachteile:**
- Noch ein Passwort zu verwalten
- Keine GUI
- Weniger flexibel als Bitwarden

**Implementierung:**
```bash
# Erstelle verschlüsselte Vars-Datei
ansible-vault create roles/secrets/vars/main.yml

# Inhalt:
---
ssh_keys:
  - name: id_ed25519_github
    private_key: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      ...
      -----END OPENSSH PRIVATE KEY-----
    public_key: "ssh-ed25519 AAAA... user@host"
    services:
      - github.com
  - name: id_ed25519_pihole
    private_key: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      ...
    public_key: "ssh-ed25519 AAAA..."
    services:
      - pihole
      - 192.168.178.32

# In Playbooks verwenden
ansible-playbook --ask-vault-pass playbooks/mac-secrets.yml
```

**Empfehlung: Nutze Bitwarden CLI**

Du hast bereits Bitwarden-Infrastruktur, also nutze sie. Ansible Vault fügt unnötig eine weitere Passwort-Schicht hinzu.

### SSH-Config-Verwaltung

**Template:** `roles/secrets/templates/ssh_config.j2`
```jinja
# Generiert von Ansible - NICHT MANUELL BEARBEITEN
# Zuletzt aktualisiert: {{ ansible_date_time.iso8601 }}

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    AddKeysToAgent yes
    UseKeychain yes

{% for server in ssh_servers %}
# {{ server.description }}
Host {{ server.alias }}
    HostName {{ server.hostname }}
    User {{ server.user }}
    Port {{ server.port | default(22) }}
    IdentityFile ~/.ssh/{{ server.key_name }}
    {% if server.forward_agent | default(false) %}
    ForwardAgent yes
    {% endif %}
    AddKeysToAgent yes
    UseKeychain yes
{% endfor %}
```

**Variablen (von Bitwarden oder Ansible Vault):**
```yaml
ssh_servers:
  - alias: pihole
    description: Home PiHole DNS Server
    hostname: 192.168.178.32
    user: pi
    key_name: id_ed25519_pihole

  - alias: digitalocean
    description: DigitalOcean VPS
    hostname: 209.38.217.45
    user: root
    key_name: id_ed25519_do
    forward_agent: yes

  - alias: allinkl
    description: All-Inkl Web Hosting
    hostname: w0103394.kasserver.com
    user: ssh-w0103394
    key_name: id_ed25519_allinkl
```

### SSH-Aliases in .zshrc

Automatisch aus Ansible-Inventory generiert:

```bash
# ~/.zshrc (generierter Abschnitt)
# SSH-Aliases - Auto-generiert von Ansible
alias ssh-pihole='ssh pihole'
alias ssh-do='ssh digitalocean'
alias ssh-allinkl='ssh allinkl'
```

### Key-Rotation

```bash
# Auf Homelab-Server
ansible-playbook playbooks/rotate-ssh-keys.yml --limit macbook-pro
# Generiert neue Keys, aktualisiert Bitwarden, deployed auf Mac, aktualisiert Server
```

### Vorteile

✅ **Keine Secrets in GitHub** - Dotfiles-Repo ist öffentlich-sicher
✅ **Zentralisierte Verwaltung** - Ein Bitwarden-Vault für alle Keys
✅ **Einfache Rotation** - Bitwarden aktualisieren, Playbook ausführen, fertig
✅ **Konsistente SSH-Config** - Alle Macs haben identisches Setup
✅ **Audit-Trail** - Ansible loggt wann Keys deployed wurden

---

## 10. Installations-Ablauf

### Frisches Mac-Setup (V2)

**Schritt 1: Bootstrap**
```bash
# Neuer Mac aus der Kiste
# Terminal.app öffnen

# Xcode Command Line Tools installieren
xcode-select --install

# Dotfiles-Repo klonen
git clone https://github.com/dbraendle/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

**Schritt 2: Installer ausführen**
```bash
./install.sh
```

**Schritt 3: Interaktives Menü**
```
╔════════════════════════════════════════════════════════════╗
║               Dotfiles V2 Installation                     ║
╚════════════════════════════════════════════════════════════╝

Erkannt: MacBook Pro (Laptop-Profil)

Installations-Optionen:
  [1] Vollständige Installation (Empfohlen)
      - System-Einstellungen (Laptop-Profil)
      - Homebrew + Alle Packages
      - Terminal (Zsh + Oh My Zsh)
      - Git-Konfiguration
      - Dock-Konfiguration
      - Netzwerk-Mounts
      - iTerm2-Konfiguration
      - Alfred-Konfiguration

  [2] Minimale Installation (Nur Core)
      - System-Einstellungen
      - Homebrew + Essentielle Packages
      - Terminal (Zsh + Oh My Zsh)
      - Git-Konfiguration

  [3] Benutzerdefiniert - Module auswählen

  [4] Profil ändern (Zu Desktop wechseln)

  [Q] Beenden

Option wählen [1-4, Q]:
```

**Schritt 4: Benutzereingabe**
```
Git-Konfiguration
-----------------
Gib deinen Git-Namen ein: Daniel Brändle
Gib deine Git-Email ein: daniel@example.com

SSH-Konfiguration
-----------------
SSH-Keys werden vom Homelab Ansible verwaltet.
Möchtest du einen temporären Key für GitHub generieren? [y/N]: y

Scanner-Konfiguration (Optional)
---------------------------------
Gib Scanner-Server-Hostname ein (leer lassen zum Überspringen): scanserver.local

Installation startet in 5 Sekunden...
Drücke Strg+C zum Abbrechen.
```

**Schritt 5: Installations-Fortschritt**
```
╔════════════════════════════════════════════════════════════╗
║                  Module installieren                       ║
╚════════════════════════════════════════════════════════════╝

[1/8] System-Einstellungen (Laptop-Profil)................... ✓
[2/8] Homebrew-Installation................................... ✓
[3/8] Brewfile-Verarbeitung (25 Packages).................... ✓
[4/8] Terminal-Setup (Zsh + Oh My Zsh)....................... ✓
[5/8] Git-Konfiguration....................................... ✓
[6/8] GNU Stow - Dotfiles verlinken........................... ✓
[7/8] Dock-Konfiguration...................................... ✓
[8/8] iTerm2-Konfiguration.................................... ✓

╔════════════════════════════════════════════════════════════╗
║              Installation Abgeschlossen! 🎉                ║
╚════════════════════════════════════════════════════════════╝

Aktive Module:
  • system (laptop-profil)
  • homebrew
  • terminal
  • git
  • dock
  • iterm2

Nächste Schritte:
  1. Terminal neu starten oder ausführen: source ~/.zshrc
  2. Im Mac App Store einloggen: mas signin
  3. Ausführen: brew bundle install  (für MAS-Apps)
  4. Homelab Ansible deployed SSH-Keys beim nächsten Lauf
  5. Anpassen: vim ~/dotfiles/zsh/.zshrc

Nützliche Befehle:
  ./manage.sh modules status       - Aktive Module anzeigen
  ./manage.sh modules list         - Alle Module auflisten
  ./manage.sh profile info         - Aktuelles Profil anzeigen
  ./update.sh                      - Manueller Update-Trigger

Installations-Log: ~/dotfiles/logs/install-2025-01-07.log
```

**Schritt 6: Erster Ansible-Lauf**
```bash
# Auf Homelab-Server (oder automatisch beim nächtlichen Cron)
ansible-playbook playbooks/mac-setup.yml --limit macbook-pro

# Deployed:
# - SSH-Keys von Bitwarden
# - SSH-Config mit Aliases
# - Beliebige zusätzliche Secrets
# - Registriert Mac für nächtliche Updates
```

---

## 11. Update-Strategie

### Update-Typen

**1. Dotfiles-Änderungen (Sofort)**
- Benutzer bearbeitet `~/dotfiles/zsh/.zshrc`
- Änderungen verlinkt, sofort aktiv
- Git commit + push
- Andere Macs erhalten Änderungen beim nächsten Ansible-Lauf (nachts)

**2. Homebrew-Packages (Nächtlich via Ansible)**
- Ansible führt aus `brew update && brew upgrade`
- Nur Minor-Versions-Updates (z.B. 1.2.3 → 1.2.4)
- Major-Versionen übersprungen (benötigen manuelle Genehmigung)

**3. npm-Packages (Nächtlich via Ansible)**
- `npm update -g` für globale Packages
- Minor-Security-Updates angewendet

**4. macOS-Security-Updates (Nächtlich via Ansible)**
- `softwareupdate --install --recommended`
- Nur Security und Minor-Patches
- **Major macOS-Versionen ausgeschlossen** (z.B. Sonoma → Sequoia)

**5. Oh My Zsh (Nächtlich via Ansible)**
- `cd ~/.oh-my-zsh && git pull`

**6. Manuelle Updates (On-Demand)**
- Benutzer führt `./update.sh` für sofortiges Update aus
- Nützlich nach Änderung von Brewfile oder System-Einstellungen

### Ansible Update-Logik

**Intelligente Update-Regeln:**
```yaml
# Homebrew - Major-Updates überspringen
- name: Liste veraltete Packages auf
  shell: brew outdated --json
  register: outdated_packages

- name: Filtere nur Minor-Updates
  set_fact:
    safe_updates: "{{ outdated_packages.stdout | from_json | selectattr('current_version', 'match', '^[0-9]+\\.[0-9]+\\.') | list }}"

- name: Aktualisiere sichere Packages
  homebrew:
    name: "{{ item.name }}"
    state: latest
  loop: "{{ safe_updates }}"

# macOS - Major-Versionen überspringen
- name: Prüfe macOS-Updates
  shell: softwareupdate --list --no-scan 2>&1
  register: macos_updates

- name: Filtere nur Security-Updates
  set_fact:
    security_updates: "{{ macos_updates.stdout_lines | select('search', 'recommended|security') | list }}"

- name: Installiere Security-Updates
  shell: softwareupdate --install --no-scan --agree-to-license {{ item }}
  loop: "{{ security_updates }}"
  become: yes
```

### Manuelles Update-Script

**Datei:** `update.sh`
```bash
#!/bin/bash
set -e

echo "╔════════════════════════════════════════╗"
echo "║     Dotfiles Manuelles Update          ║"
echo "╚════════════════════════════════════════╝"

# Neuestes von GitHub ziehen
echo "[1/6] Ziehe neueste Dotfiles von GitHub..."
git pull

# Alle aktiven Module restow
echo "[2/6] Verlinke Dotfiles neu..."
while read -r module; do
    stow -R -t ~ "$module"
done < ~/.dotfiles-modules

# Homebrew aktualisieren
echo "[3/6] Aktualisiere Homebrew-Packages..."
brew update
brew upgrade

# npm Global-Packages aktualisieren
echo "[4/6] Aktualisiere npm Global-Packages..."
npm update -g

# Oh My Zsh aktualisieren
echo "[5/6] Aktualisiere Oh My Zsh..."
(cd ~/.oh-my-zsh && git pull)

# System-Einstellungen erneut anwenden (profil-bewusst)
echo "[6/6] Wende System-Einstellungen erneut an..."
PROFILE=$(cat ~/.dotfiles-profile)
./modules/system/install.sh --profile "$PROFILE"

echo ""
echo "✅ Update abgeschlossen!"
echo "   Terminal neu starten: source ~/.zshrc"
```

### Update-Häufigkeit

| Komponente | Häufigkeit | Trigger | Major-Versionen |
|-----------|-----------|---------|----------------|
| Dotfiles | Sofort | Git commit + symlink | N/A |
| Homebrew | Nächtlich | Ansible | Nur manuell |
| npm | Nächtlich | Ansible | Nur manuell |
| macOS | Nächtlich | Ansible | **Nur manuell** |
| Oh My Zsh | Nächtlich | Ansible | N/A |
| Manuell | On-Demand | `./update.sh` | Alle Komponenten |

---

## 12. Sicherheitsverbesserungen

### Fixes für V1-Probleme

**1. Echte Server-Daten entfernen**
```bash
# Sofortmaßnahme
git rm ssh/services.json
git commit -m "Remove sensitive server data"

# Beispiel-Template erstellen
cat > ssh/services.example.json << 'EOF'
{
  "github": {
    "hostname": "github.com",
    "user": "git",
    "description": "GitHub"
  },
  "example-server": {
    "hostname": "192.168.1.100",
    "user": "dein-benutzername",
    "description": "Beispiel-Server"
  }
}
EOF

# Zu .gitignore hinzufügen
echo "ssh/services.json" >> .gitignore
echo "*.secret" >> .gitignore
echo "*.vault" >> .gitignore
```

**2. SSH-Config-Berechtigungen korrigieren**
```bash
# Im SSH-Modul-Install-Script
chmod 600 ~/.ssh/config  # Nicht 644
chmod 600 ~/.ssh/id_*    # Private Keys
chmod 644 ~/.ssh/id_*.pub # Public Keys OK
chmod 700 ~/.ssh         # Verzeichnis
```

**3. Passwort nach Ruhezustand - Profil-bewusst**
```bash
# profiles/laptop.sh
if [[ "$PROFILE" == "laptop" ]]; then
    # Passwort-Anforderung AKTIVIEREN (Sicherheit)
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
else
    # Desktop - optional
    read -p "Passwort nach Ruhezustand deaktivieren (Desktop)? [y/N]: " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        defaults write com.apple.screensaver askForPassword -int 0
    fi
fi
```

**4. Remote-Downloads verifizieren**
```bash
# Signierte Releases mit Checksummen verwenden
SSH_WUNDERBAR_VERSION="v1.0.0"
SSH_WUNDERBAR_URL="https://github.com/dbraendle/ssh-wunderbar/releases/download/${SSH_WUNDERBAR_VERSION}/ssh-wunderbar"
SSH_WUNDERBAR_SHA256="erwartete-checksum-hier"

curl -fsSL "$SSH_WUNDERBAR_URL" -o /tmp/ssh-wunderbar
echo "${SSH_WUNDERBAR_SHA256}  /tmp/ssh-wunderbar" | shasum -a 256 -c || exit 1
sudo mv /tmp/ssh-wunderbar /usr/local/bin/
```

**5. CUPS Web-Interface - Optional**
```bash
# Nur aktivieren wenn benötigt
read -p "CUPS Web-Interface aktivieren (http://localhost:631)? [y/N]: " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cupsctl WebInterface=yes
    echo "⚠️  CUPS erreichbar unter http://localhost:631 (nur localhost)"
fi
```

**6. Alias-Sicherheit - Nur Interaktiv**
```bash
# .zshrc - Nur in interaktiven Shells überschreiben
if [[ $- == *i* ]]; then
    # Sicher Commands im interaktiven Modus zu überschreiben
    alias ls='eza'
    alias cat='bat'
    alias grep='rg'
fi
```

**7. Secrets in .gitignore**
```bash
# .gitignore
.env
.env.*
*.secret
*.vault
ssh/services.json
ssh/id_*
*.key
*.pem
.ssh-services.json
mounts.config  # Kann interne IPs enthalten
.DS_Store
```

**8. Shellcheck-Integration**
```bash
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: v0.9.0.2
    hooks:
      - id: shellcheck
        args: [--severity=warning]

# Pre-commit installieren
brew install pre-commit
cd ~/dotfiles
pre-commit install
```

### Sicherheits-Checkliste

- [ ] Keine echten IPs/Benutzernamen im Repository
- [ ] SSH-Config-Berechtigungen: 600
- [ ] Private-Keys-Berechtigungen: 600
- [ ] Passwort nach Ruhezustand: auf Laptops aktiviert
- [ ] CUPS Web-Interface: dokumentiert + optional
- [ ] Remote-Downloads: Checksummen verifiziert
- [ ] Secrets: in Bitwarden/Ansible Vault gespeichert
- [ ] .gitignore: deckt alle sensiblen Dateien ab
- [ ] Shellcheck: läuft bei Pre-commit
- [ ] Firewall: standardmäßig aktiviert

---

## 13. Datei-Struktur

### V2 Verzeichnis-Layout

```
~/dotfiles/
├── install.sh                  # Haupt-Installations-Script
├── update.sh                   # Manueller Update-Trigger
├── manage.sh                   # Modul-Verwaltungs-CLI
├── README.md                   # Benutzer-Dokumentation
├── SECURITY.md                 # Sicherheits-Überlegungen
├── CHANGELOG.md                # Versions-Historie
├── LICENSE                     # MIT-Lizenz
├── .gitignore                  # Secrets-Ausschluss
├── .editorconfig               # Editor-Standards
├── .pre-commit-config.yaml     # Shellcheck-Integration
│
├── lib/                        # Geteilte Utilities
│   ├── colors.sh               # Farb-Definitionen
│   ├── logging.sh              # Print-Funktionen
│   ├── utils.sh                # Allgemeine Funktionen
│   └── stow-helpers.sh         # Stow-Wrapper
│
├── profiles/                   # Geräte-Profile
│   ├── desktop.sh              # Desktop-Einstellungen
│   └── laptop.sh               # Laptop-Einstellungen
│
├── modules/                    # Modulare Komponenten
│   ├── system/                 # macOS System-Einstellungen
│   │   ├── module.json
│   │   ├── install.sh
│   │   ├── uninstall.sh
│   │   └── settings/
│   │       ├── finder.sh
│   │       ├── keyboard.sh
│   │       ├── trackpad.sh
│   │       └── security.sh
│   │
│   ├── homebrew/               # Paket-Manager
│   │   ├── module.json
│   │   ├── install.sh
│   │   ├── update.sh
│   │   └── Brewfile
│   │
│   ├── terminal/               # Shell-Konfiguration
│   │   ├── module.json
│   │   ├── install.sh
│   │   └── README.md
│   │
│   ├── git/                    # Git-Konfiguration
│   │   ├── module.json
│   │   ├── install.sh
│   │   └── README.md
│   │
│   ├── dock/                   # Dock-Verwaltung
│   │   ├── module.json
│   │   ├── install.sh
│   │   ├── uninstall.sh
│   │   └── dock-apps.txt
│   │
│   ├── mounts/                 # Netzwerk-Mounts
│   │   ├── module.json
│   │   ├── install.sh
│   │   ├── uninstall.sh
│   │   ├── mounts.config.example
│   │   └── README.md
│   │
│   ├── ssh/                    # SSH-Konfiguration
│   │   ├── module.json
│   │   ├── install.sh
│   │   ├── services.example.json
│   │   └── README.md
│   │
│   ├── printer/                # Drucker-Setup
│   │   ├── module.json
│   │   ├── install.sh
│   │   └── README.md
│   │
│   ├── iterm2/                 # iTerm2-Konfiguration
│   │   ├── module.json
│   │   ├── install.sh
│   │   └── README.md
│   │
│   ├── alfred/                 # Alfred Workflows
│   │   ├── module.json
│   │   ├── install.sh
│   │   └── README.md
│   │
│   ├── scanner/                # Scanner-Shortcuts
│   │   ├── module.json
│   │   ├── install.sh
│   │   └── scan-shortcuts.sh
│   │
│   ├── development/            # Dev-Tools
│   │   ├── module.json
│   │   ├── install.sh
│   │   └── docker-config.json
│   │
│   └── creative/               # Kreativ-Tools
│       ├── module.json
│       ├── install.sh
│       └── README.md
│
├── config/                     # Stow-Packages (verlinkt)
│   ├── zsh/
│   │   ├── .zshrc
│   │   └── .zshenv
│   │
│   ├── git/
│   │   └── .gitconfig
│   │
│   ├── ssh/                    # Nur Template (Ansible verwaltet echte)
│   │   └── .ssh/
│   │       └── config.template
│   │
│   ├── iterm2/
│   │   └── Library/
│   │       └── Preferences/
│   │           └── com.googlecode.iterm2.plist
│   │
│   ├── alfred/
│   │   └── Library/
│   │       └── Application Support/
│   │           └── Alfred/
│   │
│   └── vscode/                 # OPTIONAL - nur wenn nicht GitHub Sync
│       └── .config/
│           └── Code/
│               └── User/
│                   └── settings.json
│
├── scripts/                    # Utility-Scripts
│   ├── bootstrap.sh            # Erstmalig-Setup
│   ├── backup.sh               # Backup vor Änderungen erstellen
│   ├── restore.sh              # Aus Backup wiederherstellen
│   └── uninstall.sh            # Komplette Deinstallation
│
├── docs/                       # Dokumentation
│   ├── installation.md
│   ├── modules.md
│   ├── homelab-integration.md
│   ├── troubleshooting.md
│   └── migration-v1-to-v2.md
│
├── logs/                       # Installations-Logs (gitignored)
│   └── .gitkeep
│
└── backups/                    # Backups vor Änderungen (gitignored)
    └── .gitkeep
```

### Vergleich: V1 vs V2

| V1 (Aktuell) | V2 (Vorgeschlagen) |
|--------------|---------------|
| `install.sh` (593 Zeilen) | `install.sh` (200 Zeilen) + Module |
| `.zshrc` kopiert nach `~/.zshrc` | `config/zsh/.zshrc` verlinkt |
| `Brewfile` im Root | `modules/homebrew/Brewfile` |
| `ssh/ssh-setup.sh` (1012 Zeilen) | `modules/ssh/` (Ansible-verwaltet) |
| Hardcodierte Farben in jedem Script | `lib/colors.sh` geteilt |
| Kein Profil-System | `profiles/desktop.sh`, `profiles/laptop.sh` |
| Keine Modul-Verwaltung | `manage.sh modules enable/disable` |
| Manuelle Updates | Ansible nächtliche Updates |

---

## 14. Tools & Technologien

### Kern-Technologien

**1. GNU Stow**
- **Zweck:** Symlink-Farm-Manager
- **Installation:** `brew install stow`
- **Verwendung:** `stow -d ~/dotfiles/config -t ~ zsh git`
- **Warum:** Änderungen sofort reflektiert, kein Sync nötig

**2. Ansible**
- **Zweck:** Homelab-Orchestrierung
- **Installation:** Auf Homelab-Server via `pip install ansible`
- **Verwendung:** `ansible-playbook playbooks/mac-update.yml`
- **Warum:** Zentralisierte Updates, Secrets-Verwaltung, nächtliche Automatisierung

**3. Bitwarden CLI**
- **Zweck:** Secrets-Speicherung und -Abruf
- **Installation:** `brew install bitwarden-cli`
- **Verwendung:** `bw get item "ssh-key" | jq -r '.notes'`
- **Warum:** Bereits in Nutzung, sicher, zugänglich, integriert mit Ansible

**4. Homebrew**
- **Zweck:** Paket-Verwaltung
- **Installation:** Automatisch in install.sh
- **Verwendung:** `brew bundle install`
- **Warum:** Standard macOS Paket-Manager

**5. Oh My Zsh**
- **Zweck:** Zsh-Framework
- **Installation:** Automatisch im Terminal-Modul
- **Verwendung:** Plugins und Themes
- **Warum:** Reiches Ökosystem, gute Defaults

**6. dockutil**
- **Zweck:** Dock-Verwaltungs-CLI
- **Installation:** `brew install dockutil`
- **Verwendung:** `dockutil --add /Applications/VSCode.app`
- **Warum:** Automatisiere Dock-Konfiguration

**7. mas**
- **Zweck:** Mac App Store CLI
- **Installation:** `brew install mas`
- **Verwendung:** `mas install 497799835`  # Xcode
- **Warum:** Automatisiere MAS-App-Installation

### Entwicklungs-Tools

**8. shellcheck**
- **Zweck:** Shell-Script-Linting
- **Installation:** `brew install shellcheck`
- **Verwendung:** `shellcheck install.sh`
- **Warum:** Fehler fangen bevor sie passieren

**9. shfmt**
- **Zweck:** Shell-Script-Formatierung
- **Installation:** `brew install shfmt`
- **Verwendung:** `shfmt -w -i 4 install.sh`
- **Warum:** Konsistenter Code-Stil

**10. pre-commit**
- **Zweck:** Git Pre-commit Hooks
- **Installation:** `brew install pre-commit`
- **Verwendung:** `pre-commit install`
- **Warum:** Automatisches Linting beim Commit

**11. jq**
- **Zweck:** JSON-Verarbeitung
- **Installation:** `brew install jq`
- **Verwendung:** module.json-Dateien parsen
- **Warum:** Modul-Metadaten-Parsing

### Optionale Tools

**12. chezmoi** (Alternative zu Stow)
- **Zweck:** Dotfile-Manager mit Templating
- **Warum NICHT genutzt:** Stow ist simpler, kein Templating benötigt
- **Könnte genutzt werden:** Wenn komplexes Pro-Maschine-Templating erforderlich

**13. yadm** (Alternative zu Stow)
- **Zweck:** Git-basierter Dotfile-Manager
- **Warum NICHT genutzt:** Weniger flexibel als Stow + Ansible
- **Könnte genutzt werden:** Wenn einfacheres Setup bevorzugt (kein Ansible)

**14. Nix / nix-darwin** (Fortgeschrittene Alternative)
- **Zweck:** Deklarative System-Konfiguration
- **Warum NICHT genutzt:** Steile Lernkurve, Overkill für 3 Macs
- **Könnte genutzt werden:** Wenn Skalierung auf 10+ Maschinen

---

## 15. Migrationspfad

### V1 → V2 Migrations-Strategie

**Phase 1: V1 sichern**
```bash
cd ~/Dev/dotfiles
git checkout -b v1-backup
git push origin v1-backup

# Manuelles Backup erstellen
cp -r ~/Dev/dotfiles ~/dotfiles-v1-backup-$(date +%Y%m%d)
```

**Phase 2: Repository umstrukturieren**
```bash
# V2-Branch erstellen
git checkout -b v2-development

# Neue Verzeichnis-Struktur erstellen
mkdir -p lib profiles modules config scripts docs logs backups

# Bestehende Dateien zu Modulen verschieben
mkdir -p modules/homebrew
mv Brewfile modules/homebrew/

mkdir -p modules/system
mv macos-settings.sh modules/system/install.sh

mkdir -p modules/dock
mv dock-setup.sh modules/dock/install.sh
mv dock-apps.txt modules/dock/

mkdir -p modules/mounts
mv mount-setup.sh modules/mounts/install.sh
mv mounts.config.example modules/mounts/

# Dotfiles nach config/ für Stow verschieben
mkdir -p config/zsh config/git
mv .zshrc config/zsh/
mv .gitconfig config/git/

# Geteilte Libraries erstellen
cat > lib/colors.sh << 'EOF'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
EOF

cat > lib/logging.sh << 'EOF'
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
EOF

# Umstrukturierung committen
git add .
git commit -m "Restructure for V2 architecture"
```

**Phase 3: Kern-Komponenten implementieren**
```bash
# Neue install.sh mit modularer Architektur erstellen
# manage.sh für Modul-Verwaltung erstellen
# module.json für jedes Modul erstellen
# README.md mit V2-Dokumentation aktualisieren

git add .
git commit -m "Implement V2 core components"
```

**Phase 4: Auf einzelnem Mac testen**
```bash
# Auf MacBook Pro (Test-Maschine)
cd ~/dotfiles
git fetch
git checkout v2-development

# Aktuelle Configs sichern
./scripts/backup.sh

# V2-Installer ausführen
./install.sh

# Alle Module testen
./manage.sh modules status
./manage.sh modules list

# Symlinks verifizieren
ls -la ~ | grep "\->"

# Updates testen
./update.sh

# Bei Problemen, Rollback
./scripts/restore.sh
```

**Phase 5: Ansible-Integration**
```bash
# Auf Homelab-Server
cd ~/homelab/ansible

# Playbooks für V2 erstellen
mkdir -p playbooks/dotfiles-v2
# mac-update.yml, mac-secrets.yml, mac-setup.yml implementieren

# Auf einzelnem Mac testen
ansible-playbook playbooks/mac-update.yml --limit macbook-pro --check
ansible-playbook playbooks/mac-update.yml --limit macbook-pro

# Auf Mac verifizieren
ssh macbook-pro
cd ~/dotfiles
git status  # Sollte "Your branch is up to date" zeigen
```

**Phase 6: Auf alle Macs ausrollen**
```bash
# V2 in main mergen
cd ~/dotfiles
git checkout main
git merge v2-development
git push origin main

# Ansible-Rollout auf alle Macs
cd ~/homelab/ansible
ansible-playbook playbooks/mac-setup.yml --limit macs

# Auf jedem Mac verifizieren
ansible macs -m shell -a "cd ~/dotfiles && git status"
```

**Phase 7: Nächtliche Updates aktivieren**
```bash
# Auf Homelab-Server
crontab -e
# Hinzufügen:
0 3 * * * cd ~/homelab/ansible && ansible-playbook playbooks/mac-update.yml >> /var/log/ansible-mac-updates.log 2>&1

# Ersten Lauf überwachen
tail -f /var/log/ansible-mac-updates.log
```

### Rollback-Plan

Falls V2 Probleme verursacht:

```bash
# Auf betroffenem Mac
cd ~/dotfiles
git checkout v1-backup

# Aus Backup wiederherstellen
./scripts/restore.sh

# Oder manuelle Wiederherstellung
cp -r ~/dotfiles-v1-backup-YYYYMMDD/* ~/

# V1-Installer erneut ausführen
./install.sh
```

---

## 16. Implementierungs-Roadmap

### Phase 1: Fundament (Woche 1-2)

**Woche 1: Repository-Umstrukturierung**
- [ ] V2-Branch erstellen
- [ ] Neue Verzeichnis-Struktur implementieren
- [ ] Dateien zu modules/ verschieben
- [ ] Geteilte lib/-Dateien erstellen (colors, logging, utils)
- [ ] Profil-System erstellen (desktop.sh, laptop.sh)
- [ ] .gitignore für Secrets aktualisieren
- [ ] Sensible Daten aus Repository entfernen
- [ ] Beispiel-Templates erstellen (services.example.json, mounts.config.example)

**Woche 2: Kern-Scripts**
- [ ] install.sh mit modularer Architektur neu schreiben
- [ ] manage.sh für Modul-Verwaltung erstellen
- [ ] module.json-Schema implementieren
- [ ] Modul install/uninstall-Scripts erstellen
- [ ] GNU Stow Integration implementieren
- [ ] shellcheck zu pre-commit hooks hinzufügen
- [ ] Unit-Tests für Kern-Funktionen schreiben
- [ ] README.md mit V2-Dokumentation aktualisieren

### Phase 2: Module (Woche 3-4)

**Woche 3: Essentielle Module**
- [ ] Modul: system (macOS-Einstellungen, profil-bewusst)
- [ ] Modul: homebrew (Brewfile, Auto-Updates)
- [ ] Modul: terminal (Zsh, Oh My Zsh, stow-verwaltet)
- [ ] Modul: git (Config mit Platzhaltern, stow-verwaltet)
- [ ] Sicherheitsprobleme beheben (Berechtigungen, Passwort nach Ruhezustand, CUPS)
- [ ] Module einzeln testen
- [ ] Module in Kombination testen

**Woche 4: Optionale Module**
- [ ] Modul: dock (dockutil, apps.txt)
- [ ] Modul: mounts (autofs, config-gesteuert)
- [ ] Modul: ssh (nur Template, Ansible-verwaltet)
- [ ] Modul: iterm2 (Config via stow)
- [ ] Modul: alfred (Einstellungen via stow)
- [ ] Modul: printer (CUPS-Konfiguration)
- [ ] Modul: scanner (Shortcuts)
- [ ] Modul: development (Docker, etc.)
- [ ] Optionale Module testen

### Phase 3: Homelab-Integration (Woche 5)

**Ansible-Playbooks**
- [ ] Ansible-Inventory erstellen (hosts.yml)
- [ ] Rollen erstellen: dotfiles, secrets, updates
- [ ] mac-update.yml implementieren (nächtliche Updates)
- [ ] mac-setup.yml implementieren (Erstinstallation)
- [ ] mac-secrets.yml implementieren (SSH-Keys, Zertifikate)
- [ ] Bitwarden CLI auf Homelab-Server einrichten
- [ ] SSH-Keys zu Bitwarden migrieren
- [ ] SSH-Config-Template erstellen (Jinja2)
- [ ] Ansible-Playbooks auf einzelnem Mac testen
- [ ] Cron-Job für nächtliche Updates einrichten

**Secrets-Verwaltung**
- [ ] Bitwarden CLI auf Homelab-Server installieren
- [ ] SSH-Keys in Bitwarden als Secure Notes speichern
- [ ] API-Tokens speichern (GitHub, etc.)
- [ ] Ansible-Tasks zum Abrufen von Secrets erstellen
- [ ] Secrets-Distribution auf Macs testen
- [ ] Secrets-Verwaltungs-Prozess dokumentieren

### Phase 4: Testing & Dokumentation (Woche 6)

**Testing**
- [ ] V2 auf MacBook Pro testen (Laptop-Profil)
- [ ] V2 auf Mac Mini testen (Desktop-Profil)
- [ ] Modul enable/disable testen
- [ ] Manuelle Updates testen (./update.sh)
- [ ] Ansible-getriggerte Updates testen
- [ ] Frische Mac-Installation testen (VM oder Ersatzgerät)
- [ ] Rollback zu V1 testen
- [ ] Alle entdeckten Bugs beheben

**Dokumentation**
- [ ] README.md mit V2-Architektur aktualisieren
- [ ] SECURITY.md mit Überlegungen erstellen
- [ ] CHANGELOG.md mit Versions-Historie erstellen
- [ ] docs/installation.md schreiben
- [ ] docs/modules.md schreiben (Nutzungs-Guide)
- [ ] docs/homelab-integration.md schreiben
- [ ] docs/troubleshooting.md schreiben
- [ ] docs/migration-v1-to-v2.md schreiben
- [ ] Demo-Video aufnehmen (optional)

### Phase 5: Rollout (Woche 7)

**Produktions-Deployment**
- [ ] v2-development in main mergen
- [ ] Release taggen: v2.0.0
- [ ] Alle Macs vor Migration sichern
- [ ] install.sh auf MacBook Pro ausführen
- [ ] install.sh auf Mac Mini ausführen
- [ ] install.sh auf MacBook Air ausführen (Server)
- [ ] Ansible nächtliche Updates aktivieren
- [ ] Erste Woche nächtlicher Updates überwachen
- [ ] Alle Module auf korrektes Funktionieren verifizieren
- [ ] Secrets-Distribution verifizieren
- [ ] Symlinks nach Updates verifizieren

### Phase 6: Wartung (Laufend)

**Regelmäßige Aufgaben**
- [ ] Wöchentlich: Ansible-Update-Logs überprüfen
- [ ] Monatlich: SSH-Keys rotieren (falls Richtlinie erfordert)
- [ ] Monatlich: Brewfile überprüfen und bereinigen
- [ ] Quartalsweise: Modul-Nutzung überprüfen, Ungenutzte entfernen
- [ ] Quartalsweise: Dokumentation aktualisieren
- [ ] Jährlich: Major macOS-Updates (manuell)

**Kontinuierliche Verbesserung**
- [ ] Module nach Bedarf hinzufügen
- [ ] Ansible-Playbooks verfeinern
- [ ] Update-Performance optimieren
- [ ] Test-Abdeckung erweitern
- [ ] Community-Feedback integrieren (falls Open-Source)

---

## 17. Zusammenfassung

### Kernänderungen von V1 zu V2

| Aspekt | V1 (Aktuell) | V2 (Vorgeschlagen) |
|--------|-------------|---------------|
| **Config-Verwaltung** | Dateien bei Installation kopieren | GNU Stow Symlinks |
| **Updates** | Manuell `./update.sh` | Ansible nächtliche Automatisierung |
| **Secrets** | Im Repo committed | Bitwarden CLI / Ansible Vault |
| **SSH** | Lokales ssh-wunderbar | Homelab Ansible Distribution |
| **Modularität** | Monolithische Scripts | Modular mit CLI-Verwaltung |
| **Profile** | Einheitsgröße | Desktop vs. Laptop Profile |
| **Sicherheit** | Probleme vorhanden | Gehärtete Berechtigungen & Praktiken |
| **Code-Qualität** | Duplikation, kein Linting | Geteilte Libs, shellcheck |
| **Dokumentation** | Von Realität abgedriftet | Akkurat, umfassend |
| **Skalierbarkeit** | 3 Macs, manueller Sync | N Macs, automatischer Sync |

### Vorteile von V2

**Für dich:**
✅ **Weniger manuelle Arbeit** - Einmal in Git bearbeiten, Änderungen propagieren automatisch
✅ **Konsistente Macs** - Alle Maschinen identisch, zentral verwaltet
✅ **Homelab-Integration** - Nutzt deine bestehende Ansible-Infrastruktur
✅ **Sicherheit** - Keine Secrets im öffentlichen Repo, korrekte Berechtigungen
✅ **Flexibilität** - Module pro Maschine aktivieren/deaktivieren
✅ **Wartbarkeit** - Sauberer Code, keine Duplikation, leicht erweiterbar
✅ **Seelenfrieden** - Nächtliche Security-Updates, Backups, Audit-Trail

**Für deinen Workflow:**
✅ **Neuer Mac-Setup** - 30 Minuten statt Stunden
✅ **Config-Änderungen** - Datei bearbeiten, committen, fertig (kein Sync nötig)
✅ **Updates** - Automatisch jede Nacht (außer Major macOS)
✅ **Disaster-Recovery** - Git klonen + install.sh = wiederhergestellter Mac
✅ **Experimentieren** - Änderungen auf einem Mac testen, auf alle ausrollen

### Nächste Schritte

**Sofortmaßnahmen (Diese Woche):**
1. ✅ Diese komplette Roadmap lesen
2. [ ] Klärende Fragen stellen
3. [ ] Über Secrets-Verwaltung entscheiden (Bitwarden CLI empfohlen)
4. [ ] V2-Branch erstellen: `git checkout -b v2-development`
5. [ ] Phase 1 starten: Repository-Umstrukturierung

**Kurzfristig (Nächste 2 Wochen):**
1. [ ] Neue Verzeichnis-Struktur implementieren
2. [ ] Geteilte lib/-Dateien erstellen
3. [ ] Profil-System implementieren
4. [ ] Sensible Daten aus Repo entfernen

**Mittelfristig (Nächste 4 Wochen):**
1. [ ] install.sh mit modularer Architektur neu schreiben
2. [ ] Alle Kern-Module implementieren
3. [ ] GNU Stow Integration hinzufügen
4. [ ] Auf einzelnem Mac testen

**Langfristig (Nächste 6 Wochen):**
1. [ ] Ansible-Playbooks erstellen
2. [ ] Bitwarden CLI auf Homelab einrichten
3. [ ] Nächtliche Updates aktivieren
4. [ ] Auf alle Macs ausrollen

### Geschätzte Timeline

**Konservativ:** 6-8 Wochen (1-2 Stunden pro Tag)
**Aggressiv:** 4 Wochen (3-4 Stunden pro Tag)
**Realistisch:** 6 Wochen mit durchschnittlich 2 Stunden pro Tag

### Erfolgsmetriken

V2 ist erfolgreich wenn:
- ✅ Alle 3 Macs laufen auf V2-Dotfiles
- ✅ Ansible nächtliche Updates funktionieren
- ✅ Keine Secrets im GitHub-Repository
- ✅ GNU Stow verwaltet alle Dotfiles
- ✅ Profil-System funktioniert (Desktop vs. Laptop)
- ✅ Alle Module getestet und dokumentiert
- ✅ Frisches Mac-Setup in unter 30 Minuten abgeschlossen
- ✅ Du kannst beliebige Config-Datei bearbeiten und sie ist sofort aktiv
- ✅ Änderungen propagieren innerhalb 24 Stunden auf alle Macs
- ✅ Keine manuelle Intervention für 95% der Updates nötig

### Risiko-Minderung

**Risiken:**
1. **Bestehendes Setup kaputt machen** → Minderung: V2-Branch, Backups, Rollback-Plan
2. **Ansible-Komplexität** → Minderung: Mit einfachen Playbooks starten, iterieren
3. **Stow-Konflikte** → Minderung: Bestehende Configs vor Stowing sichern
4. **Zeit-Investment** → Minderung: Modularer Ansatz, in Phasen arbeiten
5. **Lernkurve** → Minderung: Umfassende Dokumentation, zuerst auf einem Mac testen

### Abschließende Gedanken

V1 hat dir gute Dienste geleistet - es ist funktional und umfassend. Aber es hat die Grenzen des manuellen Managements für mehrere Maschinen erreicht. V2 nimmt das starke Fundament von V1 (Modularität, Umfang, gute UX) und fügt hinzu:

- **Automatisierung** via Ansible
- **Zentralisierung** via Homelab
- **Symlinks** via GNU Stow
- **Sicherheit** via ordentliches Secrets-Management
- **Profile** für gerätespezifische Einstellungen

Die Investition in V2 wird sich innerhalb von Wochen auszahlen - jede Config-Änderung propagiert automatisch, Security-Updates passieren nächtlich, und neue Macs sind in 30 Minuten statt einem ganzen Tag manueller Einrichtung fertig.

**Deine V1-Dotfiles erhalten eine B-. V2 wird eine A sein.**

---

**Dokument-Version:** 1.0.0
**Zuletzt aktualisiert:** 2025-01-07
**Feedback:** Issues öffnen unter https://github.com/dbraendle/dotfiles/issues
**Fragen:** Dokumentation in docs/ überprüfen oder in Discussions fragen

---

## Anhang: Schnellreferenz

### Nützliche Befehle

```bash
# Installation
./install.sh                              # Interaktive Installation
./install.sh --profile laptop             # Laptop-Profil erzwingen
./install.sh --modules core,dock,iterm2   # Spezifische Module auswählen

# Modul-Verwaltung
./manage.sh modules list                  # Alle Module auflisten
./manage.sh modules status                # Aktive Module anzeigen
./manage.sh modules enable dock           # Modul aktivieren
./manage.sh modules disable dock          # Modul deaktivieren

# Profil-Verwaltung
./manage.sh profile info                  # Aktuelles Profil anzeigen
./manage.sh profile set laptop            # Zu Laptop-Profil wechseln
./manage.sh profile set desktop           # Zu Desktop-Profil wechseln

# Updates
./update.sh                               # Manuelles Update
./update.sh --force                       # Alle Module zwangs-restow

# Stow-Operationen
cd ~/dotfiles
stow -t ~ zsh git                         # Spezifische Packages stow
stow -R -t ~ zsh                          # Restow (neue Dateien aufnehmen)
stow -D -t ~ zsh                          # Unstow (Symlinks entfernen)
stow -n -v -t ~ zsh                       # Dry-Run (zeigen was passieren würde)

# Ansible (auf Homelab-Server)
ansible-playbook playbooks/mac-update.yml              # Alle Macs aktualisieren
ansible-playbook playbooks/mac-update.yml --limit macbook-pro  # Einen Mac aktualisieren
ansible-playbook playbooks/mac-secrets.yml             # Secrets deployen
ansible macs -m shell -a "cd ~/dotfiles && git status" # Git-Status auf allen Macs prüfen

# Backup & Restore
./scripts/backup.sh                       # Backup erstellen
./scripts/restore.sh                      # Aus Backup wiederherstellen
./scripts/uninstall.sh                    # Komplette Deinstallation

# Debugging
./install.sh --debug                      # Verbose-Ausgabe
./manage.sh modules status --verbose      # Detaillierte Modul-Info
cat ~/.dotfiles-modules                   # Aktive Module ansehen
cat ~/.dotfiles-profile                   # Aktuelles Profil ansehen
ls -la ~ | grep "\->"                     # Symlinks verifizieren
```

### Datei-Pfade

```
~/dotfiles/                    # Dotfiles-Repository
~/.zshrc -> ~/dotfiles/config/zsh/.zshrc   # Verlinkte zshrc
~/.gitconfig -> ~/dotfiles/config/git/.gitconfig   # Verlinkte gitconfig
~/.dotfiles-modules            # Liste aktiver Module
~/.dotfiles-profile            # Aktuelles Profil (desktop/laptop)
~/.dotfiles-update.log         # Ansible-Update-Historie
~/dotfiles/logs/               # Installations-Logs
~/dotfiles/backups/            # Config-Backups
```

### Fehlerbehebung

**Problem: Stow weigert sich Symlink zu erstellen**
**Lösung:** Bestehende Datei am Zielpfad. Zuerst sichern und entfernen.
```bash
mv ~/.zshrc ~/.zshrc.backup
stow -t ~ zsh
```

**Problem: Ansible kann nicht zu Mac verbinden**
**Lösung:** SSH-Zugang sicherstellen, Firewall prüfen.
```bash
ssh mac-mini  # SSH-Verbindung testen
ssh-copy-id mac-mini  # SSH-Key kopieren falls nötig
```

**Problem: Modul lässt sich nicht aktivieren**
**Lösung:** Abhängigkeiten prüfen.
```bash
./manage.sh modules info dock  # Modul-Anforderungen ansehen
cat modules/dock/module.json   # Dependencies-Array prüfen
```

**Problem: Änderungen propagieren nicht zu anderen Macs**
**Lösung:** Ansible-Cron-Job prüfen, Update manuell triggern.
```bash
# Auf Homelab-Server
ansible-playbook playbooks/mac-update.yml --limit macbook-pro
tail -f /var/log/ansible-mac-updates.log
```

**Problem: Symlink nach macOS-Update kaputt**
**Lösung:** Alle Module restow.
```bash
cd ~/dotfiles
while read module; do stow -R -t ~ "$module"; done < ~/.dotfiles-modules
```

### Ressourcen

- GNU Stow Handbuch: https://www.gnu.org/software/stow/manual/
- Ansible Dokumentation: https://docs.ansible.com/
- Bitwarden CLI: https://bitwarden.com/help/cli/
- Homebrew: https://brew.sh/
- Oh My Zsh: https://ohmyz.sh/
- ShellCheck: https://www.shellcheck.net/

---

**Ende der Roadmap**
