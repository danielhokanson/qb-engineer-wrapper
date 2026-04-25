#!/usr/bin/env bash
#
# split.sh — extract qb-engineer-wrapper into 5 history-preserving repos.
#
# Source repo (read-only): the one this script lives in.
# Destination: /tmp/qb-engineer-split/{ui,server,deploy,test,master}/
#
# Each output is a fully-formed git repo with a `develop` branch off main,
# pointed at https://github.com/<OWNER>/<repo>.git, ready to push.
#
# Usage:
#   bash cicd-plan/split.sh                    # local extractions only (review)
#   bash cicd-plan/split.sh --push             # also push to GitHub (irreversible-ish)
#
# Requires: git-filter-repo (https://github.com/newren/git-filter-repo)
#   pipx install git-filter-repo  OR  brew install git-filter-repo
#
# Substitute <OWNER> with your GitHub user/org before running:
#   sed -i 's|<OWNER>|your-github-name|g' cicd-plan/split.sh

set -euo pipefail

OWNER="<OWNER>"
SOURCE_REPO="$(git rev-parse --show-toplevel)"
WORK_DIR="/tmp/qb-engineer-split"
PUSH=false

if [[ "${1:-}" == "--push" ]]; then
  PUSH=true
fi

if [[ "$OWNER" == "<OWNER>" ]]; then
  echo "ERROR: Substitute <OWNER> with your GitHub user/org before running."
  echo "       sed -i 's|<OWNER>|your-github-name|g' cicd-plan/split.sh"
  exit 1
fi

if ! command -v git-filter-repo >/dev/null 2>&1; then
  echo "ERROR: git-filter-repo not found. Install with:"
  echo "       pipx install git-filter-repo  OR  brew install git-filter-repo"
  exit 1
fi

echo "Source repo:  $SOURCE_REPO"
echo "Work dir:     $WORK_DIR"
echo "GitHub owner: $OWNER"
echo "Push?         $PUSH"
echo

# Wipe previous run; we always start clean.
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

# ----------------------------------------------------------------------------
# Helper: clone source, run filter-repo with given path specs, set up branches,
# wire up the remote, optionally push.
#
# Arguments:
#   $1 = repo short name (ui | server | deploy | test | master)
#   $2..N = paths to KEEP (passed to git-filter-repo --path)
# ----------------------------------------------------------------------------
extract() {
  local name="$1"
  shift
  local paths=("$@")
  local target="$WORK_DIR/$name"
  local remote="https://github.com/$OWNER/qb-engineer-$name.git"
  # Master is just "qb-engineer", not "qb-engineer-master"
  if [[ "$name" == "master" ]]; then
    remote="https://github.com/$OWNER/qb-engineer.git"
  fi

  echo "============================================================"
  echo "Extracting: qb-engineer-$([[ "$name" == "master" ]] && echo "" || echo "$name")"
  echo "Paths kept:"
  for p in "${paths[@]}"; do echo "  $p"; done
  echo "============================================================"

  # 1. Clone source as a working copy. --no-local would force HTTPS-style copy;
  # we want a fast local clone that filter-repo can rewrite freely.
  git clone "$SOURCE_REPO" "$target"
  cd "$target"

  # 2. Run filter-repo with the path specs. --invert-paths is NOT used —
  # we keep only what's listed.
  local args=()
  for p in "${paths[@]}"; do
    args+=(--path "$p")
  done
  git filter-repo "${args[@]}" --force

  # 3. Promote the kept content if it was nested under a single directory.
  # For ui/server/test: filter-repo keeps the directory structure
  # (qb-engineer-ui/src/...). We want repo root to be the contents.
  case "$name" in
    ui)
      git filter-repo --subdirectory-filter qb-engineer-ui --force
      ;;
    server)
      git filter-repo --subdirectory-filter qb-engineer-server --force
      ;;
    test)
      git filter-repo --subdirectory-filter test-plans --force
      ;;
    deploy|master)
      # Multi-source repos — keep paths as-is.
      ;;
  esac

  # 4. Wire up the remote.
  git remote add origin "$remote"

  # 5. Create develop branch off main (whatever the source's default branch is).
  local default_branch
  default_branch="$(git symbolic-ref --short HEAD)"
  if [[ "$default_branch" != "main" ]]; then
    git branch -m "$default_branch" main
  fi
  git branch develop main

  # 6. Tag v0.0.1 on main as the initial release marker.
  git tag -a v0.0.1 -m "Initial extraction from qb-engineer-wrapper monorepo"

  # 7. Optionally push.
  if [[ "$PUSH" == true ]]; then
    git push -u origin main
    git push -u origin develop
    git push --tags
  fi

  cd "$SOURCE_REPO"
  echo
}

# ----------------------------------------------------------------------------
# UI repo: just qb-engineer-ui/
# ----------------------------------------------------------------------------
extract ui \
  qb-engineer-ui

# ----------------------------------------------------------------------------
# Server repo: just qb-engineer-server/
# ----------------------------------------------------------------------------
extract server \
  qb-engineer-server

# ----------------------------------------------------------------------------
# Deploy repo: docker-compose + setup/refresh scripts + ops glue.
# Keep history for these even though they're scattered — filter-repo handles
# multi-path extractions cleanly.
# ----------------------------------------------------------------------------
extract deploy \
  docker-compose.yml \
  docker-compose.cohost.yml \
  docker-compose.demo.yml \
  docker-compose.dev.yml \
  docker-compose.export.yml \
  setup.sh \
  setup.ps1 \
  refresh.sh \
  refresh.ps1 \
  setup-demo.sh \
  refresh-demo.sh \
  export-demo-data.sh \
  export-demo-data.ps1 \
  scripts \
  maintenance \
  tools

# ----------------------------------------------------------------------------
# Test repo: just test-plans/ (already exists on GitHub but needs first push)
# ----------------------------------------------------------------------------
extract test \
  test-plans

# ----------------------------------------------------------------------------
# Master repo: README, LICENSE, docs, specs, top-level governance.
# CLAUDE.md migrates here too — it's project-level guidance.
# ----------------------------------------------------------------------------
extract master \
  README.md \
  LICENSE \
  CLAUDE.md \
  docs \
  specs

echo "============================================================"
echo "Extraction complete."
echo "  $WORK_DIR/ui      -> github.com/$OWNER/qb-engineer-ui"
echo "  $WORK_DIR/server  -> github.com/$OWNER/qb-engineer-server"
echo "  $WORK_DIR/deploy  -> github.com/$OWNER/qb-engineer-deploy"
echo "  $WORK_DIR/test    -> github.com/$OWNER/qb-engineer-test"
echo "  $WORK_DIR/master  -> github.com/$OWNER/qb-engineer"
echo
if [[ "$PUSH" == false ]]; then
  echo "No --push flag given. Inspect the local extractions, then re-run with"
  echo "--push (or push manually with 'git push -u origin main' from each dir)."
else
  echo "Pushed to GitHub. Next: copy CI/CD workflow files from cicd-plan/workflows/"
  echo "into each repo and commit."
fi
