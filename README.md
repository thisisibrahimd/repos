# repos

Hop between your repos with ease.

## Prereqs

You must have [fzf](https://github.com/junegunn/fzf) installed. The optional
`launch` feature also needs [jq](https://jqlang.github.io/jq/), `curl`, and a
[TypeSafe](https://typesafe.ai) API key; `r` needs none of those and stays fully
offline.

## Install

curl

```bash
curl -fsSL https://github.com/thisisibrahimd/repos/releases/download/latest/repos -o ~/.local/bin/repos
```

mise

```bash
mise use github:thisisibrahimd/repos
```

## Shell Integration

In order to change directories within your current shell session, you must add init snippt to your respective shell
configuration file. The hook also registers tab completion: `repos <Tab>` completes
subcommands and flags, and `r <Tab>` completes repository paths (bare or work
tree) under `$REPOS_DIR`, matched by full path or repo name. No extra tools
are needed at completion time. The hook also installs `rl` for description-based
jumps (see Launch by description below).

Bash

```bash
# ~/.bashrc
eval "$(repos init bash)"
```

Zsh

```zsh
# ~/.zshrc
eval "$(repos init zsh)"
```

## Usage

1.  ```repos``` relies on the following directory structure to work correctly.
It reflects the url paths that repos are usually stored in from Github, Gitlab, and
other git hosts.

```<repos-dir>/<git-host-domain>/<repo-owner>/<repo-name>```

```bash
# your default repos dir
~/repos
  # git host domain
  github.com/
    # repo owner
    kubernetes/
      # repository names
      kubernetes
      minikube
      kubeadm
  gitlab.com/
    ...
```

2. Set the location of your repos dir in your shell.

```bash
# ~/.zshrc
# default is ~/repos
export REPOS_DIR=~/repos
```

3. After successfuly configuration of the cli and implementation of folder structure, you may simply run ```repos``` to hop into any repo of your choosing with ```fzf```.

The picker finds repositories by content, not by depth: a directory is a repo if
it holds a `.git` entry (work tree) or `HEAD` plus git dirs (bare). Repos are
labelled `(bare)` or `(work)` in the picker, and nested owner paths such as
GitLab subgroups (`gitlab.com/group/subgroup/repo`) work at any depth.

Full CLI reference: [docs/reference.md](docs/reference.md), generated from
[repos.usage.kdl](repos.usage.kdl) with [usage](https://github.com/jdx/usage).
`usage` is a dev-only tool; it is never required at runtime or completion time.

## Creating and cloning

```bash
# clone bare (default), into the layout below, prints the path
repos clone https://github.com/thisisibrahimd/repos.git
repos clone git@github.com:thisisibrahimd/repos.git
repos clone thisisibrahimd/repos          # shorthand, host defaults to github.com

# clone with a work tree, no .git suffix
repos clone --no-bare https://github.com/thisisibrahimd/repos.git

# start a new repo under your own owner
repos create thisisibrahimd/my-new-repo
```

Bare is the default; opt out per call with `--no-bare` or persistently with
`REPOS_BARE=0` in your shell. Bare destinations always get the `.git` suffix.

| Env | Default | Meaning |
| --- | --- | --- |
| `REPOS_DIR` | `~/repos` | Root of the repo tree |
| `REPOS_BARE` | `1` | `0`/`false` makes clone/create non-bare; `--bare`/`--no-bare` override |
| `REPOS_TYPESAFE_API_KEY` (or `JEV_KEY`) | unset | Enables `repos launch`; no key means `r` only |
| `JEV_CONFIDENCE` | `0.5` | Minimum calibrated confidence before `launch` jumps without asking |

## Launch by description (optional, uses Jev)

When you don't remember a repo's name — only what you were doing in it — describe
the work and `repos` jumps you there. The match is semantic, powered by
[Jev](https://typesafe.ai), a fast decision model; it sees the same repos the
picker sees, including bare ones and nested owners.

```bash
export REPOS_TYPESAFE_API_KEY="your-key"   # enables launch; r works without it
rl "the one that handles the auth group sync"
```

`rl` is installed by `repos init`, alongside `r`. On a confident match it `cd`s
into the repo; on a weak, absent, or API-error case it falls back to the ordinary
`r` picker, so it is never a dead end. `repos launch "<desc>"` prints the path
instead of changing directories (that is what the hook uses).

Launch is **opt-in and online**: it sends only lightweight metadata — repo name,
remote, README first heading, branch names, and recent commit subjects — never
file contents. `r` never leaves your machine.

## Worktrees

`repos` never creates worktrees. If the picked repo has any, a second `fzf`
stage offers them, so `r` can drop you straight into a worktree (including the
bare repo root). Create new worktrees with
[worktrunk](https://github.com/dandavison/worktrunk): `cd` into a bare repo and
run `wt switch <branch>`; its default `.worktrees/<name>` layout is what
`repos` lists.

```bash
r                     # repo → worktree → you are there
cd "$(repos clone owner/repo)" && wt switch new-feature
```

