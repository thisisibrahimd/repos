# Example repos — `repos launch` demo sandbox

A synthetic `REPOS_DIR` for trying `launch` without touching your real repos.
Every repo here has an **intentionally unhelpful name**, but rich content
(remote, README, branch names, commit subjects) — the exact signals `launch`
reads. So `r` (fuzzy on the name) can't find them, and `launch "<what I was
doing>"` can.

## Setup

```bash
./examples/build.sh            # generate 14 fake repos under examples/acme-repos/
cd examples && direnv allow    # pins REPOS_DIR to the example tree, here and below it
```

With direnv active, any shell inside `examples/` (or deeper) has `REPOS_DIR`
pointed at `examples/acme-repos/` — never your `~/repos`. The API key comes
from the worktree's `.env` (`REPOS_TYPESAFE_API_KEY`, or the `JEV_KEY` testing
alias); this dir stores no secrets.

Or without direnv, per command:

```bash
REPOS_DIR="$PWD/examples/acme-repos" ./repos launch "the billing and invoices one"
```

## The showcase — queries where the name tells you nothing

| You type | It lands in | Why `r` fails |
|---|---|---|
| "the billing and invoice reconciliation one" | `acmeorg/telesto` | "Telesto" is a moon of Saturn |
| "search application logs" | `acmeorg/owl` | nothing in the name says logs |
| "the live collaborative cursors repo" | `acmeorg/kite` | codename |
| "geocoding addresses and map tiles" | `acmeorg/compass` | "compass" reads as generic |
| "the nightly ETL jobs for athena" | `acme-labs/flux` | codename |
| "the public status page during incidents" | `acmeorg/beacon` | codename |
| "page on-call when an alert fires" | `acmeorg/siren` | codename |
| "toggle a feature flag / experiments" | `acmeorg/marmot` | codename |
| "the rails monolith we're carving apart" | `acmeorg/monolith` | lives on `gitlab.com`, not `github.com` |

Each of those is matched on branch names + commit subjects + remote, **not**
the name — which is the whole argument for the feature.

## It also abstains

`launch` never makes a silent wrong jump. A query with nothing to match
returns nothing and exits non-zero, so the `rl` hook falls through to the
ordinary `r` picker:

```bash
./repos launch "the rust compiler frontend"
# launch: no repo matched "the rust compiler frontend"   (exit 1)
```

Below `JEV_CONFIDENCE` (default `0.5`) it prints the ranked candidates to
stderr and abstains the same way.

## Rebuild / inspect

The generated `acme-repos/` tree is git-ignored and each entry is itself a git
repo, so re-run `build.sh` freely — it wipes and regenerates. To see exactly
what the model is fed for one repo:

```bash
source <(sed -n '/^_repo_descriptor/,/^}/p' repos)
_repo_descriptor "$PWD/examples/acme-repos/github.com/acmeorg/telesto"
```
