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
