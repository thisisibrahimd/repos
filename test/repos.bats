#!/usr/bin/env bats
# Test suite for the repos script.
#
# Conventions:
#   - PATH prepends test/stub/fzf (deterministic fzf). Real git is used
#     unless a test also prepends test/stub/git.
#   - REPOS_DIR points into $BATS_TEST_TMPDIR, never the real ~/repos.

setup() {
  # deterministic dummy identity: CI runners have no git user configured,
  # and fixtures commit here (mono_fixture).
  export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
  export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
  SCRIPT="$BATS_TEST_DIRNAME/../repos"
  FZF_STUB="$BATS_TEST_DIRNAME/stub/fzf"
  GIT_STUB="$BATS_TEST_DIRNAME/stub/git"
  chmod +x "$FZF_STUB/fzf" "$GIT_STUB/git"
  REPOS="$BATS_TEST_TMPDIR/repos"
  mkdir -p "$REPOS"
  # physical path: macOS $TMPDIR is under the /var -> /private/var symlink
  REPOS="$(cd "$REPOS" && pwd -P)"
}

# Run the script with stub fzf on PATH.
run_repos() {
  PATH="$FZF_STUB:$PATH" REPOS_DIR="$REPOS" run bash "$SCRIPT" "$@"
}

# Run the script with stub fzf AND stub git (clone/create behavior).
run_repos_gitstub() {
  GIT_STUB_LOG="$BATS_TEST_TMPDIR/git.log" \
    PATH="$GIT_STUB:$FZF_STUB:$PATH" REPOS_DIR="$REPOS" \
    run bash "$SCRIPT" "$@"
}

# Evaluate a shell expression in a bash that sourced the script.
eval_fn() {
  run bash -c "source '$SCRIPT'; $1"
}

# --- _repos_parse_source ---------------------------------------------------

@test "parse: https url with .git suffix" {
  eval_fn '_repos_parse_source https://github.com/markazos/markazos.git && printf "%s|%s|%s|%s" "$_SRC_HOST" "$_SRC_OWNER" "$_SRC_REPO" "$_SRC_URL"'
  [ "$status" -eq 0 ]
  [ "$output" = "github.com|markazos|markazos|https://github.com/markazos/markazos.git" ]
}

@test "parse: https url trailing slash, no .git" {
  eval_fn '_repos_parse_source https://github.com/markazos/markazos/ && printf "%s|%s|%s" "$_SRC_HOST" "$_SRC_OWNER" "$_SRC_REPO"'
  [ "$status" -eq 0 ]
  [ "$output" = "github.com|markazos|markazos" ]
}

@test "parse: scp-style ssh url" {
  eval_fn '_repos_parse_source git@github.com:markazos/markazos.git && printf "%s|%s|%s|%s" "$_SRC_HOST" "$_SRC_OWNER" "$_SRC_REPO" "$_SRC_URL"'
  [ "$status" -eq 0 ]
  [ "$output" = "github.com|markazos|markazos|git@github.com:markazos/markazos.git" ]
}

@test "parse: ssh:// url with user" {
  eval_fn '_repos_parse_source ssh://git@github.com/markazos/markazos.git && printf "%s|%s|%s" "$_SRC_HOST" "$_SRC_OWNER" "$_SRC_REPO"'
  [ "$status" -eq 0 ]
  [ "$output" = "github.com|markazos|markazos" ]
}

@test "parse: owner/repo shorthand defaults to github.com ssh url" {
  eval_fn '_repos_parse_source markazos/markazos && printf "%s|%s|%s|%s" "$_SRC_HOST" "$_SRC_OWNER" "$_SRC_REPO" "$_SRC_URL"'
  [ "$status" -eq 0 ]
  [ "$output" = "github.com|markazos|markazos|git@github.com:markazos/markazos.git" ]
}

@test "parse: host/owner/repo shorthand rebuilds ssh url" {
  eval_fn '_repos_parse_source gitlab.com/foo/bar && printf "%s|%s" "$_SRC_HOST" "$_SRC_URL"'
  [ "$status" -eq 0 ]
  [ "$output" = "gitlab.com|git@gitlab.com:foo/bar.git" ]
}

@test "parse: gitlab subgroup keeps nested owner" {
  eval_fn '_repos_parse_source https://gitlab.com/group/subgroup/repo.git && printf "%s|%s|%s" "$_SRC_HOST" "$_SRC_OWNER" "$_SRC_REPO"'
  [ "$status" -eq 0 ]
  [ "$output" = "gitlab.com|group/subgroup|repo" ]
}

@test "parse: rejects bare name without slash" {
  eval_fn '_repos_parse_source just-a-repo'
  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot parse source"* ]]
}

@test "parse: rejects url without owner" {
  eval_fn '_repos_parse_source https://github.com/repo-only'
  [ "$status" -eq 1 ]
}

@test "parse: rejects path traversal" {
  eval_fn '_repos_parse_source owner/../repo'
  [ "$status" -eq 1 ]
}

@test "parse: rejects url-form dot-dot traversal in owner" {
  eval_fn '_repos_parse_source https://github.com/o/../../../../outside/victim.git'
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid path segment"* ]]
}

@test "parse: rejects dot-dot as host segment" {
  eval_fn '_repos_parse_source https://../../etc/passwd'
  [ "$status" -eq 1 ]
}

@test "parse: rejects source starting with dash" {
  eval_fn '_repos_parse_source -c protocol.ext.enabled=true/x/y'
  [ "$status" -eq 1 ]
  [[ "$output" == *'must not start with "-"'* ]]
}

@test "parse: rejects ext:: command-exec transport" {
  eval_fn "_repos_parse_source \"ext::sh -c touch /tmp/pwned\""
  [ "$status" -eq 1 ]
  [[ "$output" == *"unsupported source scheme"* ]]
}

@test "parse: rejects unknown scheme" {
  eval_fn '_repos_parse_source fish://github.com/o/r'
  [ "$status" -eq 1 ]
  [[ "$output" == *"unsupported scheme"* ]]
}

@test "parse: accepts git:// scheme" {
  eval_fn '_repos_parse_source git://github.com/o/r && printf "%s|%s" "$_SRC_HOST" "$_SRC_URL"'
  [ "$status" -eq 0 ]
  [ "$output" = "github.com|git://github.com/o/r" ]
}

@test "parse: rejects tab in repo segment" {
  eval_fn '_repos_parse_source "owner/re	po"'
  [ "$status" -eq 1 ]
}

# --- bare resolution ---------------------------------------------------------

@test "bare: default is 1" {
  eval_fn '_repos_resolve_bare ""'
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "bare: REPOS_BARE=0 opts out" {
  eval_fn 'REPOS_BARE=0 _repos_resolve_bare ""'
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "bare: REPOS_BARE=false opts out" {
  eval_fn 'REPOS_BARE=false _repos_resolve_bare ""'
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "bare: flag beats env" {
  eval_fn 'REPOS_BARE=0 _repos_resolve_bare 1'
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "bare: invalid REPOS_BARE errors" {
  eval_fn 'REPOS_BARE=yes _repos_resolve_bare ""'
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid REPOS_BARE"* ]]
}

# --- clone -------------------------------------------------------------------

@test "clone: default is bare with .git suffix" {
  run_repos_gitstub clone https://github.com/markazos/markazos.git
  [ "$status" -eq 0 ]
  [ "$output" = "$REPOS/github.com/markazos/markazos.git" ]
  [ -f "$REPOS/github.com/markazos/markazos.git/HEAD" ]
  [ -f "$BATS_TEST_TMPDIR/git.log" ]
  run cat "$BATS_TEST_TMPDIR/git.log"
  [ "$output" = "clone --bare -- https://github.com/markazos/markazos.git $REPOS/github.com/markazos/markazos.git" ]
}

@test "clone: --no-bare gives work tree without suffix" {
  run_repos_gitstub clone --no-bare https://github.com/markazos/markazos.git
  [ "$status" -eq 0 ]
  [ "$output" = "$REPOS/github.com/markazos/markazos" ]
  [ -d "$REPOS/github.com/markazos/markazos/.git" ]
}

@test "clone: REPOS_BARE=0 opts out persistently" {
  export REPOS_BARE=0
  PATH="$GIT_STUB:$FZF_STUB:$PATH" REPOS_DIR="$REPOS" GIT_STUB_LOG="$BATS_TEST_TMPDIR/git.log" run bash "$SCRIPT" clone git@github.com:markazos/markazos.git
  [ "$status" -eq 0 ]
  [ "$output" = "$REPOS/github.com/markazos/markazos" ]
}

@test "clone: --bare beats REPOS_BARE=0" {
  PATH="$GIT_STUB:$FZF_STUB:$PATH" REPOS_BARE=0 REPOS_DIR="$REPOS" GIT_STUB_LOG="$BATS_TEST_TMPDIR/git.log" run bash "$SCRIPT" clone --bare https://github.com/markazos/markazos.git
  [ "$status" -eq 0 ]
  [[ "$output" == *.git ]]
}

@test "clone: shorthand clones via rebuilt ssh url" {
  run_repos_gitstub clone markazos/markazos
  [ "$status" -eq 0 ]
  run cat "$BATS_TEST_TMPDIR/git.log"
  [ "$output" = "clone --bare -- git@github.com:markazos/markazos.git $REPOS/github.com/markazos/markazos.git" ]
}

@test "clone: creates nested owner dirs" {
  run_repos_gitstub clone https://gitlab.com/group/subgroup/repo.git
  [ "$status" -eq 0 ]
  [ -f "$REPOS/gitlab.com/group/subgroup/repo.git/HEAD" ]
}

@test "clone: refuses traversal url, creates nothing outside REPOS_DIR" {
  mkdir -p "$BATS_TEST_TMPDIR/elsewhere"
  run_repos_gitstub clone "https://github.com/o/../../../elsewhere/victim.git"
  [ "$status" -eq 1 ]
  [ -z "$(ls -A "$BATS_TEST_TMPDIR/elsewhere")" ]
}

@test "clone: refuses existing destination" {
  mkdir -p "$REPOS/github.com/markazos/markazos.git"
  run_repos_gitstub clone https://github.com/markazos/markazos.git
  [ "$status" -eq 1 ]
  [[ "$output" == *"destination already exists"* ]]
}

@test "clone: no args is a usage error" {
  run_repos_gitstub clone
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage: repos clone"* ]]
}

@test "clone: unknown flag errors" {
  run_repos_gitstub clone --squash owner/repo
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown flag"* ]]
}

@test "clone: invalid source errors" {
  run_repos_gitstub clone "not a source"
  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot parse source"* ]]
}

# --- create ------------------------------------------------------------------

@test "create: default is bare with .git suffix" {
  run_repos_gitstub create thisisibrahimd/newrepo
  [ "$status" -eq 0 ]
  [ "$output" = "$REPOS/github.com/thisisibrahimd/newrepo.git" ]
  run cat "$BATS_TEST_TMPDIR/git.log"
  [ "$output" = "init --bare -- $REPOS/github.com/thisisibrahimd/newrepo.git" ]
}

@test "create: --no-bare gives work tree" {
  run_repos_gitstub create --no-bare thisisibrahimd/newrepo
  [ "$status" -eq 0 ]
  [ -d "$REPOS/github.com/thisisibrahimd/newrepo/.git" ]
}

@test "create: refuses existing destination" {
  mkdir -p "$REPOS/github.com/thisisibrahimd/newrepo.git"
  run_repos_gitstub create thisisibrahimd/newrepo
  [ "$status" -eq 1 ]
  [[ "$output" == *"destination already exists"* ]]
}

# --- picker ------------------------------------------------------------------

make_fixtures() {
  git init -q --bare "$REPOS/github.com/o/bare.git"
  git init -q "$REPOS/github.com/o/work"
  git init -q --bare "$REPOS/gitlab.com/group/sub/deep.git"
  # decoys: must never appear in the list
  mkdir -p "$REPOS/github.com/o/notrepo.git"                     # bare-shaped, no HEAD
  mkdir -p "$REPOS/stray.git" && touch "$REPOS/stray.git/HEAD"   # above host level
  mkdir -p "$REPOS/github.com/o/emptyowner"                      # plain dir
}

@test "picker: lists bare and work repos with kind labels, any depth" {
  make_fixtures
  FZF_STUB_LOG="$BATS_TEST_TMPDIR/list" FZF_SELECT=bare \
    PATH="$FZF_STUB:$PATH" REPOS_DIR="$REPOS" run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "$REPOS/github.com/o/bare.git" ]
  run cat "$BATS_TEST_TMPDIR/list"
  [[ "$output" == *"github.com/o/bare.git	(bare)"* ]]
  [[ "$output" == *"github.com/o/work	(work)"* ]]
  [[ "$output" == *"gitlab.com/group/sub/deep.git"* ]]
}

@test "picker: skips non-repos, nested dirs, and depth-1 strays" {
  make_fixtures
  git init -q "$REPOS/github.com/o/outer"
  git init -q "$REPOS/github.com/o/outer/inner" # nested repo must stay hidden
  FZF_STUB_LOG="$BATS_TEST_TMPDIR/list" \
    PATH="$FZF_STUB:$PATH" REPOS_DIR="$REPOS" run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  run cat "$BATS_TEST_TMPDIR/list"
  [[ "$output" != *notrepo* ]]
  [[ "$output" != *stray* ]]
  [[ "$output" != *emptyowner* ]]
  [[ "$output" != *outer/inner* ]]
}

@test "picker: skips entries whose name contains a tab" {
  make_fixtures
  mkdir -p "$REPOS/github.com/o/weird	1.git"
  touch "$REPOS/github.com/o/weird	1.git/HEAD"
  FZF_STUB_LOG="$BATS_TEST_TMPDIR/list" \
    PATH="$FZF_STUB:$PATH" REPOS_DIR="$REPOS" run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  run cat "$BATS_TEST_TMPDIR/list"
  [[ "$output" != *weird* ]]
  # every listed line is exactly path<TAB>(kind)
  run bash -c "awk -F'\t' 'NF != 2 { exit 1 }' '$BATS_TEST_TMPDIR/list'"
  [ "$status" -eq 0 ]
}

@test "picker: worktree-less bare repo returns its root, no second stage" {
  make_fixtures
  FZF_SELECT=bare.git FZF_STUB_LOG="$BATS_TEST_TMPDIR/list" \
    PATH="$FZF_STUB:$PATH" REPOS_DIR="$REPOS" run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "$REPOS/github.com/o/bare.git" ]
  # second fzf run would have overwritten the log with worktree entries
  run cat "$BATS_TEST_TMPDIR/list"
  [[ "$output" == *"github.com/o/bare.git"* ]]
}

mono_fixture() {
  # bare repo with one real worktree, all created with real git
  git init -q --bare "$REPOS/github.com/o/mono.git"
  git init -q -b main "$BATS_TEST_TMPDIR/src"
  (cd "$BATS_TEST_TMPDIR/src" && git commit -q --allow-empty -m init)
  git --git-dir="$REPOS/github.com/o/mono.git" fetch -q "$BATS_TEST_TMPDIR/src" 'refs/heads/*:refs/heads/*'
  git --git-dir="$REPOS/github.com/o/mono.git" symbolic-ref HEAD refs/heads/main
  git --git-dir="$REPOS/github.com/o/mono.git" worktree add -q "$REPOS/github.com/o/mono.git/.worktrees/feature" main
}

@test "picker: worktree stage lists bare root and worktrees, selects one" {
  mono_fixture
  FZF_STUB_COUNT="$BATS_TEST_TMPDIR/n" FZF_SELECT=mono.git FZF_SELECT2=feature \
    FZF_STUB_LOG2="$BATS_TEST_TMPDIR/stage2" \
    PATH="$FZF_STUB:$PATH" REPOS_DIR="$REPOS" run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "$REPOS/github.com/o/mono.git/.worktrees/feature" ]
  run cat "$BATS_TEST_TMPDIR/stage2"
  [[ "$output" == *"mono.git	(bare)"* ]]
  [[ "$output" == *".worktrees/feature	(worktree)"* ]]
}

@test "picker: cancel at stage 2 returns nothing" {
  mono_fixture
  FZF_STUB_COUNT="$BATS_TEST_TMPDIR/n" FZF_SELECT=mono.git FZF_CANCEL_STAGE=2 \
    PATH="$FZF_STUB:$PATH" REPOS_DIR="$REPOS" run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- misc cli --------------------------------------------------------------

@test "init hook still prints r function" {
  run bash "$SCRIPT" init bash
  [ "$status" -eq 0 ]
  [[ "$output" == *"command repos"* ]]
  [[ "$output" == *"builtin cd"* ]]
}

@test "unknown command errors" {
  run bash "$SCRIPT" frobnicate
  [ "$status" -eq 2 ]
}

@test "help prints usage" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"repos clone"* ]]
  [[ "$output" == *"REPOS_BARE"* ]]
}

@test "clone handles names with spaces" {
  run_repos_gitstub clone "https://github.com/some owner/some repo.git"
  [ "$status" -eq 0 ]
  [ -f "$REPOS/github.com/some owner/some repo.git/HEAD" ]
}
