# repos

Hop between your repos with ease.

## Prereqs

You must have [fzf](https://github.com/junegunn/fzf) installed.

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
configuration file.

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
export REPOS_DIR=~/code
```

3. After successfuly configuration of the cli and implementation of folder structure, you may simply run ```repos``` to hop into any repo of your choosing with ```fzf```.

The picker finds repositories by content, not by depth: a directory is a repo if
it holds a `.git` entry (work tree) or `HEAD` plus git dirs (bare). Repos are
labelled `(bare)` or `(work)` in the picker, and nested owner paths such as
GitLab subgroups (`gitlab.com/group/subgroup/repo`) work at any depth.

## Creating and cloning

```bash
# clone bare (default), into the layout below, prints the path
repos clone https://github.com/markazos/markazos.git
repos clone git@github.com:markazos/markazos.git
repos clone markazos/markazos          # shorthand, host defaults to github.com

# clone with a work tree, no .git suffix
repos clone --no-bare https://github.com/markazos/markazos.git

# start a new repo under your own owner
repos create thisisibrahimd/my-new-repo
```

Bare is the default; opt out per call with `--no-bare` or persistently with
`REPOS_BARE=0` in your shell. Bare destinations always get the `.git` suffix.

| Env | Default | Meaning |
| --- | --- | --- |
| `REPOS_DIR` | `~/repos` | Root of the repo tree |
| `REPOS_BARE` | `1` | `0`/`false` makes clone/create non-bare; `--bare`/`--no-bare` override |

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

