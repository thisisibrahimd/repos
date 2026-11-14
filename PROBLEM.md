# Problem Definition

## Summary

`repos` can jump my shell into any repo I already have on disk, but it cannot create one — adding a repo, or the owner directory it belongs in, still means leaving the tool and hand-building the correct path. Because the tool checks only that an entry is a directory at the right depth, anything that lands in the wrong place is never prevented and never reported.

## Content

Every repository on my machine lives under one root (`~/repos`, overridable with `REPOS_DIR`) in a fixed three-level layout mirroring a repo's URL: `<repos-dir>/<git-host-domain>/<repo-owner>/<repo-name>`, for example `~/repos/github.com/thisisibrahimd/dotfiles.git`. Whether the directory is bare, and whether its name carries a `.git` suffix, doesn't matter — both forms are acceptable and the picker handles either. "Bare" means it holds only git's version history with no editable files checked out.

`repos` exists to remove one annoyance: retyping long, predictable paths. Listing the directories at that fixed depth and piping them into `fzf` (an interactive fuzzy menu) makes the picker instant. Since a child process cannot change its parent shell's directory, the tool only prints the chosen path, and a shell function installed via `repos init` — named `r` — runs `cd` on it. So in any terminal: `r`, a few keystrokes, Enter, and I'm inside the repo without ever typing a path. That is the whole product, and it works.

Two limits were implicit in that scope and never revisited. The tool is **read-only**: it never writes to the tree, so creating owner directories, cloning, and initializing all happen by hand in raw shell outside it. And the **one rule it depends on — a repo is a git directory at exactly depth 3 under `REPOS_DIR` — is nowhere stated or checked**; `find -mindepth 3 -maxdepth 3 -type d` is the entire enforcement, and it fails by omission rather than by error.

The tree now holds 39 entries across 2 hosts and 15 owner directories, all of them created by hand.

## Impact

The tool's author and sole user (me), daily and at every project start.

**Creation is manual, and frequent.** Roughly 30 seconds of `cd`, `mkdir`, `git clone` for each new repo, plus the same dance whenever a new owner or host appears. This is routine work, not an exception, and every occurrence means leaving the tool for the step that decides where the repo goes — the one step the tool's whole value depends on getting right.

**Navigation pays a cost it shouldn't.** Dozens of jumps a day, each presenting 39 look-alike candidates in raw filesystem order with no signal about which repo I actually work in.

**Worktrees — where I often do the work — are unreachable.** I keep them at `<repo>.git/.worktrees/<name>`, which is exactly [`worktrunk`](https://github.com/dandavison/worktrunk)'s default layout. But the contents of a depth-3 directory sit at depth 4 and deeper, so the picker cannot see them. I already organize for the tool I want to integrate with, and can't reach the results with the tool I have.

**The picker trusts depth over content.** With no check that an entry is a repository, any directory at depth 3 is offered as one, and dead state lingers: `gitlab.com/` is a host directory I scaffolded by hand that is still completely empty.

**One risk I should state precisely rather than overstate.** Nothing is invisible to the picker *today*, because a depth-3 `find -type d` matches bare and non-bare directories alike, and both naming forms sort out fine. But coverage rests entirely on a hardcoded depth: a repo cloned one level off, or outside the root, would be silently excluded with no diagnostic — the only symptom being me looking for a repo and not finding it.

## Root cause

The tool models the *state* I want and none of the *transitions into* it. The single moment placement is decided is creation, and creation happens outside the tool's reach, in raw shell, at the moment I'm starting something and least inclined to do filesystem plumbing.

Three mechanisms keep it from self-correcting. **Prevention is structurally impossible:** a user-space CLI cannot forbid `mkdir`, so any tool relying only on "put it in the right place at write time" has a permanent hole, and the hole is the default path whenever the tool lacks a command. **Failure is silent:** nothing reports a misplacement, and absence of an error is read as absence of a problem. **The cost falls below the recognition threshold:** 30 seconds never feels like a tooling problem in any single instance, so it normalizes into "how it's done" and is never reclassified — even though creation is frequent enough that the aggregate is large.

The result is that a genuinely simple rule — *a repo is a git directory at depth 3 under `REPOS_DIR`* — has no owner. Naming is free-form and bare is optional, which makes the invariant narrow and easy to state; the cost is that nobody, including the code, currently states it.

## Outcome

A solution lets me manage the local repository lifecycle entirely through `repos`, so a path under `REPOS_DIR` is never hand-constructed.

1. **Derive the destination from the repo's identity on create.** `repos clone <owner>/<repo>` or a remote URL resolves its own path; `repos init` does the same for new repos. Path becomes an output rather than an input, which removes the error class instead of discouraging it, and reduces the routine case to a single command.
2. **Support both forms explicitly.** Bare or with a work tree, `.git` suffix or not — the tool should pick the sensible default per command and handle either on lookup, rather than leaving it to whatever `git clone` happened to do.
3. **Create owner directories idempotently** — one command for `mkdir -p` of a `<host>/<owner>` path, no `cd` chains.
4. **Navigate owners as well as repos,** so I can hop into an owner directory to browse or create within it.
5. **Detect and adopt misplacements.** The load-bearing capability: a scan verifying the narrow invariant — an actual git directory at exactly depth 3 — reporting stray non-repo directories, empty owners, and repos living off-depth or outside the root, plus an `adopt` command that relocates one into place. Prevention has a hard ceiling, so visibility and recoverability matter more than enforcement — and a scanner also lets the tool *migrate* the workspace if the layout ever changes, instead of only seeding forward.
6. **Enter worktrees by delegating to `worktrunk`.** List and jump to worktrees under the existing `<repo>.git/.worktrees/<name>` layout, which worktrunk already uses by default. `repos` decides *which repository*; worktrunk decides *which branch*. `repos` must not reimplement worktree creation.

Two constraints bound any solution. `r` must keep moving my shell instantly — that is the product, and anything costing it is a regression. And the required-dependency set stays `fzf` plus `git` plus POSIX: ranking should come from a small usage log the tool owns (record each successful jump, feed `fzf` a pre-sorted list with `--tiebreak=index`) rather than from `zoxide`, whose path-keyed database would be a second source of truth able to disagree with the tree — the same class of problem this work exists to eliminate.
