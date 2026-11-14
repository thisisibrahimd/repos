#!/usr/bin/env bash
#
# Build a synthetic REPOS_DIR for demos/tests of `repos launch`.
#
# The point: every repo has an intentionally unhelpful name, but rich,
# specific content (remote, README, branch names, commit subjects) — the
# exact signals `repos launch` reads. So `r` (fuzzy on the name) fails and
# `launch "<what I was doing>"` lands. Regenerate anytime; output is under
# examples/acme-repos/ and is git-ignored (each entry is itself a git repo).
#
# Usage:
#   ./examples/build.sh
#   REPOS_DIR="$PWD/examples/acme-repos" rl "the billing and invoices one"
#
set -eu -o pipefail

here=$(cd "$(dirname "$0")" && pwd)
ROOT="$here/acme-repos"
rm -rf "$ROOT"
mkdir -p "$ROOT"

IDENT=(-c user.name=repos-demo -c user.email=demo@acme.test)

# mkrepo <host/owner/name> <remote> <README-H1> <c1~c2~c3> <branch1~branch2>
#   commits go on the default branch; extra branches are named after the task
#   (branch names are part of the descriptor, so they carry signal too).
mkrepo() {
  local rel="$1" remote="$2" h1="$3" commits="$4" branches="${5:-}"
  local dir="$ROOT/$rel"
  mkdir -p "$dir"
  git "${IDENT[@]}" -C "$dir" -c init.defaultBranch=main init -q
  printf '# %s\n\nInternal service — see the runbook for on-call and deploy details.\n' "$h1" > "$dir/README.md"
  git "${IDENT[@]}" -C "$dir" add -A
  # split ~-joined commit subjects into individual commits
  local IFS='~'
  for msg in $commits; do
    [[ -n "$msg" ]] || continue
    printf '%s\n' "$msg" > "$dir/CHANGELOG.md"   # touch a file so each commit differs
    git "${IDENT[@]}" -C "$dir" add -A
    git "${IDENT[@]}" -C "$dir" commit -q -m "$msg"
  done
  unset IFS
  # feature branches, named for the work in them
  if [[ -n "$branches" ]]; then
    local IFS='~'
    for br in $branches; do
      [[ -n "$br" ]] || continue
      git "${IDENT[@]}" -C "$dir" checkout -q -b "$br" main
      printf '# %s\n' "$br" > "$dir/NOTES.md"
      git "${IDENT[@]}" -C "$dir" add -A
      git "${IDENT[@]}" -C "$dir" commit -q -m "wip: start ${br##*/}"
      git "${IDENT[@]}" -C "$dir" checkout -q main
    done
    unset IFS
  fi
  [[ -n "$remote" ]] && git "${IDENT[@]}" -C "$dir" remote add origin "$remote"
}

# name           remote                                          H1            commits                                                     branches
mkrepo "github.com/acmeorg/auth-service"   "git@github.com:acmeorg/auth-service.git"  "Auth Service" "init auth service~feat: Authentik group sync~fix: OIDC refresh token rotation"      "feat/group-sync~fix/sso-redirect-loop"
mkrepo "github.com/acmeorg/image-service"  "git@github.com:acmeorg/image-service.git" "Image Service" "init~feat: libvips resize pipeline~feat: serve webp to browsers"                    "feat/webp-transcode"

# The codename cases — name is meaningless, only content resolves the query.
mkrepo "github.com/acmeorg/telesto"        "git@github.com:acmeorg/telesto.git"       "Telesto"      "init~refactor: nightly billing reconciliation~feat: stripe invoice export~fix: dunning emails"  "feat/reconciliation~feat/dunning-emails"
mkrepo "github.com/acmeorg/marmot"         "git@github.com:acmeorg/marmot.git"        "Marmot"       "init~feat: feature-flag evaluation service~feat: experiment bucketing"                        "feat/experimentation"
mkrepo "github.com/acmeorg/beacon"         "git@github.com:acmeorg/beacon.git"        "Beacon"       "init~feat: public incident status page~feat: email subscribers on outage"                     "feat/incident-comms"
mkrepo "github.com/acmeorg/siren"          "git@github.com:acmeorg/siren.git"         "Siren"        "init~route alerts to slack channel~feat: on-call escalation policy"                             "feat/on-call-rotation"
mkrepo "github.com/acmeorg/drift"          "git@github.com:acmeorg/drift.git"         "Drift"        "init~feat: terraform plan/apply orchestrator~fix: drift detection on tfstate"                  "feat/tf-drift-detect"
mkrepo "github.com/acmeorg/owl"            "git@github.com:acmeorg/owl.git"           "Owl"          "init~feat: query loki for app logs~feat: live tail streaming"                                   "feat/loki-tail"
mkrepo "github.com/acmeorg/kite"           "git@github.com:acmeorg/kite.git"          "Kite"         "init~feat: realtime cursor presence over websockets~CRDT cursor sync"                           "feat/cursor-presence"
mkrepo "github.com/acmeorg/carousel"       "git@github.com:acmeorg/carousel.git"      "Carousel"     "init~feat: astro marketing site~feat: pricing page with plans table"                              "feat/pricing-page"
mkrepo "github.com/acmeorg/compass"        "git@github.com:acmeorg/compass.git"       "Compass"      "init~feat: geocode postal addresses~feat: serve map tiles"                                      "feat/geocoding"

# A second owner on the same host.
mkrepo "github.com/acme-labs/flux"         "git@github.com:acme-labs/flux.git"        "Flux"         "init~feat: nightly ETL to S3 for Athena~fix: partition pruning"                                  "feat/etl-tuning"
mkrepo "github.com/acme-labs/gatekeeper"   "git@github.com:acme-labs/gatekeeper.git"  "Gatekeeper"   "init~feat: API rate limiting gateway~feat: token bucket per key"                                 "feat/rate-limit"

# A second git host, to show multi-<host>/<owner> layout.
mkrepo "gitlab.com/acmeorg/monolith"       "git@gitlab.com:acmeorg/monolith.git"      "Monolith"     "init~legacy rails monolith~refactor: extract payments into gem"                                  "extract/payments"

n=$(find "$ROOT" -type d -mindepth 3 -maxdepth 3 | wc -l | tr -d ' ')
echo "built $n example repos under $ROOT"
