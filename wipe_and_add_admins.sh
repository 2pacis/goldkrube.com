#!/usr/bin/env bash
set -euo pipefail

# USAGE:
# ./wipe_and_add_admins.sh <REPO_URL> <GITHUB_USER_ZAVIL> <GITHUB_USER_MANAGER> [MAIN_BRANCH]
# Example:
# ./wipe_and_add_admins.sh https://github.com/2pacis/goldkrube.com.git zavil-github manager-github main

REPO_URL="${1:-https://github.com/2pacis/goldkrube.com.git}"
GIT_USER_ZAVIL="${2:-<GITHUB_USERNAME_FOR_ZAVIL>}"
GIT_USER_MANAGER="${3:-<GITHUB_USERNAME_FOR_MANAGER>}"
MAIN_BRANCH="${4:-main}"   # ändere falls 'master' o.ä.

WORKDIR="$(mktemp -d)/goldkrube_workdir_$(date +%s)"
BACKUP_DIR="$(pwd)/goldkrube-backups"
TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"

echo "=== Vorbereitung ==="
echo "Repo: $REPO_URL"
echo "Zavil GitHub-User: $GIT_USER_ZAVIL"
echo "Manager GitHub-User: $GIT_USER_MANAGER"
echo "Main branch (für Force-Push, optional): $MAIN_BRANCH"
echo "Arbeitsverzeichnis: $WORKDIR"
mkdir -p "$BACKUP_DIR"

echo
echo "=== Schritt 1: Backup (mirror) erstellen ==="
git clone --mirror "$REPO_URL" "${BACKUP_DIR}/goldkrube-backup-${TIMESTAMP}.git" >/dev/null
echo "Backup (bare mirror) erstellt: ${BACKUP_DIR}/goldkrube-backup-${TIMESTAMP}.git"

echo
echo "=== Schritt 2: Klonen für Arbeit ==="
git clone "$REPO_URL" "$WORKDIR"
cd "$WORKDIR"

# optional: sicherstellen, wir haben alle branches/refs
git fetch --all --prune

echo
echo "=== Schritt 3: neuen Branch anlegen und Dateien löschen ==="
NEW_BRANCH="wipe-everything-${TIMESTAMP}"
git checkout -b "$NEW_BRANCH"

# Entferne tracked Dateien
git rm -r --cached . || true
# Lösche verbleibende Dateien im Arbeitsverzeichnis (Vorsicht: .git bleibt erhalten)
# Behutsam: lösche alles außer .git-Verzeichnis
shopt -s extglob
rm -rf !( .git )
shopt -u extglob

# ADMIN-Datei anlegen mit den gewünschten Namen (statisch nach Wunsch)
cat > ADMIN.txt <<EOF
Admin: Zavil Goldack
Manager: Manager Goldack
Datum: $TIMESTAMP (UTC)
Hinweis: Repo wurde geleert per Skript.
EOF

git add ADMIN.txt
git commit -m "Repo wiped — set Admin: Zavil Goldack, Manager: Manager Goldack" || {
  echo "Commit fehlgeschlagen (evtl. keine Änderungen). Abbruch."
  exit 1
}

echo
echo "=== Schritt 4: Push new branch ==="
git push origin "$NEW_BRANCH"
echo "Branch '$NEW_BRANCH' wurde gepusht. Prüfe auf GitHub."

echo
echo "=== Optional: main direkt überschreiben ==="
echo "Wenn du MAIN sofort ersetzen möchtest, führe (auf eigene Gefahr) den folgenden Befehl aus:"
echo "  git push --force origin $NEW_BRANCH:$MAIN_BRANCH"
echo
echo "Hinweis: Dieser Force-Push überschreibt $MAIN_BRANCH komplett."

echo
echo "=== Schritt 5: Collaborators hinzufügen (GitHub CLI 'gh' erforderlich) ==="
echo "Wenn du 'gh' installiert und authentifiziert hast (gh auth login), kannst du diese Befehle benutzen:"
echo "  gh repo add-collaborator $(echo "$REPO_URL" | sed -E 's@https://github.com/@@; s/\.git$//') $GIT_USER_ZAVIL --permission admin"
echo "  gh repo add-collaborator $(echo "$REPO_URL" | sed -E 's@https://github.com/@@; s/\.git$//') $GIT_USER_MANAGER --permission admin"
echo
echo "Wenn du keine 'gh' Nutzung willst: verwende die Web-UI -> Settings -> Manage access -> Invite a collaborator."

echo
echo "=== Fertig ==="
echo "Backup liegt in: $BACKUP_DIR"
echo "Arbeitskopie: $WORKDIR"
echo "Gepusht: Branch = $NEW_BRANCH"
echo
echo "WICHTIG: Ich kann die Operation nicht für dich ausführen — führe dieses Skript lokal aus."
