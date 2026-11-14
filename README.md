# repos

Hop between your repos with ease.

## Prereqs

You must have [fzf](https://github.com/junegunn/fzf) and [git](https://git-scm.com) installed.

For the optional `launch` feature you also need [jq](https://jqlang.github.io/jq/), `curl`, and a
[TypeSafe](https://typesafe.ai) API key (its Jev model powers the semantic match). `r` needs none of
those — it is fully offline.

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

0.  ```repos``` relies on the following directory structure to work correctly.
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

1. Set the location of your repos dir in your shell.

```bash
# ~/.zshrc
# default is ~/repos
export REPOS_DIR=~/code
```

2. After successfuly configuration of the cli and implementation of folder structure, you may simply run ```repos``` to hop into any repo of your choosing with ```fzf```.

## Launch by description (optional, uses Jev)

When you don't remember a repo's name — only what you were doing in it — describe the work and
`repos` jumps you there. This is powered by [Jev](https://typesafe.ai), a fast, type-safe decision
model, so the match is semantic rather than fuzzy-by-string.

```bash
export REPOS_TYPESAFE_API_KEY="your-key"   # enables launch; r works without it
rl "the one that handles the auth group sync"
```

`rl` is installed by `repos init`, alongside `r`. On a confident match it `cd`s into the repo; on a
weak or no match it falls back to the ordinary `r` picker, so it is never a dead end. Set
`JEV_CONFIDENCE` (0-1, default `0.5`) to tune how sure it must be before it jumps.

Privacy: launch is **opt-in and online**. It sends only lightweight metadata — repo name, remote,
README first heading, branch names, and recent commit subjects — never file contents. `r` never
leaves your machine.
