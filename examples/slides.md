---
marp: true
theme: default
paginate: true
transition: fade
style: |
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');
  section {
    background: #21252b;
    color: #abb2bf;
    font-family: 'Inter', system-ui, sans-serif;
    font-size: 26px;
    line-height: 1.45;
    padding: 54px 64px;
  }
  h1, h2, h3, strong { color: #e6e8ef; }
  h1 { font-size: 52px; letter-spacing: -0.03em; }
  h2 { font-size: 40px; letter-spacing: -0.02em; }
  h1, h2 { font-weight: 600; }
  code, kbd { font-family: 'JetBrains Mono', monospace; }
  :not(pre) > code {
    background: #1c2027; color: #e5c07b; padding: 2px 7px; border-radius: 5px; font-size: 0.92em;
  }
  pre {
    background: #16191f; border: 1px solid #3e4451; border-radius: 10px;
    padding: 18px 22px; font-size: 20px; color: #dcdfe4; overflow: auto;
  }
  pre code { color: #dcdfe4; }
  a { color: #61afef; text-decoration: none; }
  table { border-collapse: collapse; width: 100%; font-size: 22px; }
  th, td { text-align: left; padding: 9px 14px; border-bottom: 1px solid #343a46; }
  th { color: #61afef; font-weight: 600; font-family: 'JetBrains Mono', monospace; font-size: 15px; letter-spacing: .06em; text-transform: uppercase; }
  td code { background: transparent; color: #56b6c2; padding: 0; }
  .lead { justify-content: center; }
  .lead h1 { font-size: 64px; }
  .kicker { color: #98c379; font-family: 'JetBrains Mono', monospace; font-size: 17px; letter-spacing: .14em; text-transform: uppercase; }
  .accent { color: #61afef; }
  .green { color: #98c379; }
  .purple { color: #c678dd; }
  .muted { color: #7f848e; }
  .big { font-size: 34px; }
  .term-prompt { color: #98c379; }
  section::after { color: #5c6370; font-family: 'JetBrains Mono', monospace; }
---

<!-- _class: lead -->
<div class="kicker">$ a CLI for people who live in the terminal</div>

# repos

### Describe your work. Land in the repo.

<span class="muted">`r` finds repos by name. `repos launch` finds them by what they <em>do</em>.</span>

---

## The problem

You have **~360 repos** on disk. You can't find one of them.

Not because the tool is slow — because **repo names carry no signal.**

<div class="big" style="margin-top:18px">
<code>telesto</code> &nbsp; <code>owl</code> &nbsp; <code>kite</code> &nbsp; <code>compass</code> &nbsp; <code>marmot</code> &nbsp; <code>flux</code>
</div>

<p class="muted" style="margin-top:16px">Fuzzy search only matches strings you <em>already remember</em>.</p>

---

## It's a vocabulary problem

The question you actually ask is a <span class="accent">task</span>, not a name:

> "which repo was I in when I fixed the **billing reconciliation**?"

The repo is called `telesto`. Nothing in that name says <em>billing</em>.

<br>

**Query ≠ document.** The gap between how work is described and how repos are named is exactly where string matching dies — and where a model earns its keep.

---

## The solution: `repos launch`

One command. A plain-language description goes in, your shell moves.

```bash
$ rl "the billing and invoice reconciliation one"
→ cd ~/repos/github.com/acmeorg/telesto
```

Three steps — **deterministic** where a machine should be, **judgment** only where a human is the source of truth:

1. **describe** → say what you're doing
2. **choose** → one fast model call ranks the repos by their content
3. **land** → high confidence jumps you in; otherwise it abstains

---

## How "choose" works

Build a tiny **descriptor** per repo from cheap local git facts, ask once:

```
remote=git@github.com:acmeorg/telesto.git
readme="# Telesto"
branches=feat/dunning-emails feat/reconciliation main
recent=fix: dunning emails · feat: stripe invoice export · nightly billing reconciliation
```

The model is **Jev** (typesafe.ai) — a ~150 ms, type-safe <span class="green">decision</span> call, not a chatbot. It returns a pick **with a calibrated confidence**, and a `none` option so it can abstain.

---

## Never a silent wrong jump

```bash
$ rl "the rust compiler frontend"          # nothing in the tree matches
launch: no repo matched — falling back to r

$ rl "search"                              # low confidence → candidates, not a guess
telesto (0.31) · owl (0.28) · beacon (0.12)
```

Below the floor, `rl` falls through to the ordinary `r` picker.

<p class="muted">A miss is never a dead end — you already have <code>r</code> prefilled.</p>

---

## The live demo — 14 fake repos

Every name is useless on purpose. `launch` lands on content alone:

| you say | it lands in |
|---|---|
| "the billing and invoice reconciliation one" | `acmeorg/telesto` |
| "search application logs" | `acmeorg/owl` |
| "the live collaborative cursors repo" | `acmeorg/kite` |
| "geocoding addresses and map tiles" | `acmeorg/compass` |
| "the nightly ETL jobs for athena" | `acme-labs/flux` |
| "the rails monolith we're carving apart" | `gitlab.com/acmeorg/monolith` |

<span class="muted">across 2 hosts · 3 owners · regenerated with <code>./examples/build.sh</code></span>

---

## Honest about privacy

`launch` calls an API, so we scope it clearly:

| | `r` (default) | `launch` (opt-in) |
|---|---|---|
| needs a key | no | yes — `REPOS_TYPESAFE_API_KEY` |
| leaves the machine | **never** | metadata only |
| what's sent | — | names, remotes, branches, commit titles |
| file contents | never | **never** |

<p class="muted">No key, no call: <code>launch</code> is just <code>r</code>.</p>

---

<!-- _class: lead -->
<div class="kicker">$ get started</div>

# Stop retyping paths.

```bash
./examples/build.sh
cd examples && direnv allow
rl "the status page during incidents"
```

<p class="muted">The repos are already on your machine. <span class="accent">repos</span> just knows where they are.</p>
