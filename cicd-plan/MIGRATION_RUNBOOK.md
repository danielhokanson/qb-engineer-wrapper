# Multi-Repo Migration Runbook

> Read this first. Everything else in `cicd-plan/` is referenced from here.

## Goal

Split the current monorepo (`qb-engineer-wrapper`) into 5 independent repos
on GitHub, with CI/CD per repo, history-preserving extractions, and an
umbrella ("master") repo that ties them together.

## Final repo layout

| Repo | Owns |
|---|---|
| `qb-engineer` | Master — README, `docs/`, `specs/`, governance, bootstrap script, release manifest |
| `qb-engineer-ui` | Angular app (current `qb-engineer-ui/`) |
| `qb-engineer-server` | .NET solution (current `qb-engineer-server/`) |
| `qb-engineer-deploy` | docker-compose, setup/refresh scripts, nginx maintenance, RFID relay |
| `qb-engineer-test` | Manual test plans (already created) |
| `qb-engineer-wrapper` | **Archived in place** — final commit adds "MOVED → qb-engineer" notice |

Independent semver per repo, all starting at `v0.0.1`. Master repo's
`release-manifest.md` records which sibling versions go together.

## Branch model

- `main` = always-tagged, production-ready
- `develop` = integration branch
- `feature/*` → PR into `develop`
- `develop` → PR into `main` for releases (which cuts a tag and triggers
  the `release.yml` workflow on GHCR)

## Two-session execution plan

### Session A — this session (review prep)

You review the artifacts below; nothing executes against GitHub.

1. **Read** `MIGRATION_RUNBOOK.md` (this file)
2. **Review** `split.sh` — the `git filter-repo` extraction script
3. **Review** `master/` — the master repo's starter content
4. **Review** `workflows/` — per-repo CI/CD workflow templates
5. **Substitute** `<OWNER>` placeholder with your GitHub user/org (sed
   one-liner at the bottom of this doc)
6. **Confirm or redirect** anything you want changed before Session B

### Session B — next session (execution)

Tested in this exact order. Each step is recoverable until the push.

1. **Pre-flight checks**
   - `git filter-repo` installed (`pipx install git-filter-repo` or
     `brew install git-filter-repo`)
   - `gh` CLI authenticated (`gh auth status`)
   - GitHub repos created and empty (see step 2)

2. **Create empty GitHub repos** — `gh repo create` commands at the
   bottom of this doc. Empty = no README, no .gitignore, no LICENSE
   (we're importing those).

3. **Run the split** — `bash cicd-plan/split.sh` from a scratch dir.
   Script clones the source monorepo into `/tmp/qb-engineer-split/`
   and produces 5 history-preserving clones in
   `/tmp/qb-engineer-split/{ui,server,deploy,test,master}/`. Source
   monorepo is **not** mutated.

4. **Inspect the splits locally** — for each split repo:
   - `git log --oneline | wc -l` (commit count sanity)
   - `ls -la` (expected files present)
   - `git remote -v` (remote correctly set)

5. **Push to GitHub** — for each split repo, `git push -u origin main`
   then `git push -u origin develop` then `git push --tags`. (The
   script can do this with `--push` flag once you've reviewed.)

6. **Add CI/CD** — copy `cicd-plan/workflows/{repo}/.github/` into each
   pushed repo, commit, push. Workflows immediately become active.

7. **Add governance** — copy `cicd-plan/master/CONTRIBUTING.md` etc.
   into the master, plus per-repo CONTRIBUTING stubs from
   `cicd-plan/per-repo-stubs/`.

8. **Verify** — bootstrap from scratch:
   ```bash
   git clone https://github.com/<OWNER>/qb-engineer.git
   cd qb-engineer && bash bootstrap.sh
   cd ../qb-engineer-deploy && cp .env.example .env && docker compose up -d
   ```
   Confirm the app runs.

9. **Archive the old repo** — push one final commit to
   `qb-engineer-wrapper` that replaces the README with a "MOVED →
   qb-engineer" notice (template in `cicd-plan/archive-notice.md`).
   Optionally enable GitHub's "Archive this repository" setting (makes
   it read-only).

10. **Update CLAUDE.md** — point at the new repo URLs so future
    Claude sessions don't get confused.

## Things deliberately not migrated

These files exist in the monorepo but won't go to any new repo:

- Scratch debug files at root: `auth_resp.json`, `login*.json`,
  `extract_result.{json,txt}`, `response.txt`, `idaho_w4.pdf`,
  `setup.json`, `template_check.json`, `addresses-v3r2_3.yaml`,
  `alpha1.json`, `check_step1.py`, `check_template.py`, `cursor.md`
- `test-results/` (gitignored already)
- `storage/` (empty, runtime-only)

If any of these turn out to matter, flag before Session B.

## Open questions still deferred

- **Release cadence** — you wanted to circle back. Default in the
  workflows: every merge to `main` builds an image tagged with the
  commit SHA + `:latest`; tag push (`vX.Y.Z`) builds the semver-tagged
  image. No automatic deployment to any environment yet. Easy to add
  later by appending a deploy job.
- **Staging environment** — none configured yet. Add when you have a
  host to deploy to.

## `<OWNER>` substitution

Once you confirm your GitHub owner (user or org), substitute everywhere:

```bash
# From cicd-plan/ — replace <OWNER> with your GitHub user/org
grep -rl '<OWNER>' . | xargs sed -i 's|<OWNER>|your-github-name|g'
```

## `gh repo create` commands

Run these in Session B (or now if you want the empty repos staged):

```bash
gh repo create <OWNER>/qb-engineer        --public --description "Manufacturing operations platform — umbrella repo"
gh repo create <OWNER>/qb-engineer-ui     --public --description "Angular UI for qb-engineer"
gh repo create <OWNER>/qb-engineer-server --public --description ".NET API + EF migrations for qb-engineer"
gh repo create <OWNER>/qb-engineer-deploy --public --description "docker-compose + ops scripts for qb-engineer"
# qb-engineer-test already exists; skip
```

All public, GPL license inherited from the imported `LICENSE` file.

## Rollback

Through step 4 (inspect local splits) — nothing has touched GitHub.
Just `rm -rf /tmp/qb-engineer-split/` and start over.

After step 5 (push) — empty the new repos via `gh repo edit
<repo> --visibility private` then delete and recreate. Original
`qb-engineer-wrapper` is untouched throughout, so you can always
re-run the split.
