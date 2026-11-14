# Product Statement — `repos launch`

## Concept

`repos` takes a plain-language description of your work and puts your shell in the matching repository: `repos launch "the one that sends welcome emails"` lands you in the right directory, or tells you nothing matched. Everything deterministic stays deterministic; a model is used only for the one step a machine genuinely owns — deciding which repo a human meant.

## Role of AI

The AI is **Jev** (typesafe.ai), a System One model — a fast, ~150 ms, type-safe **decision** API, not a chat LLM and not an embedding index. `launch` builds a compact descriptor snapshot of every repo on disk with `jq`, sends that snapshot plus the description in **one `Choice` call** ("which of these repos does this description refer to, or none"), and gets back a `choice`, `probabilities`, and a calibrated `confidence` the code branches on. It only ever picks *which existing repo you meant*; it never decides where to create anything, and it never reads file contents — names and metadata only.

Because Jev is a hosted API, the AI path is explicitly **opt-in and online**: `r` (fzf + git + POSIX) stays fully offline and is the default for the daily jumps where you know the name; `launch` is the accelerator for the times you don't, and it degrades to lexical `r` when no API key is set.

## Data / inputs

The `Choice` state is a `jq`-built descriptor per repo: its name, `<host>/<owner>`, remote URL, README first heading, top dependency names (`package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml`), branch names, and recent commit subjects. **Repo scope only** — worktrees are out of this feature. Optionally the per-jump usage log tilts an ambiguous match toward the repo you actually work in. No embedding model, no rebuildable index, no file contents, no code upload.

## User experience

`r` is untouched — instant, model-free, fuzzy-by-name, for the jumps where you already know what you want. `repos launch "..."` covers the times you don't: describe the work, get one Jev `Choice` verdict back in well under a second, and branch on `confidence` — high lands you in the directory via the same `r` hook, mid shows the top candidates ranked by probability, low or `none` falls through to `r` prefilled with near-misses, so a miss is never a dead end. The online step is opt-in (needs `REPOS_JEV_KEY`) and sends metadata only; with no key, `launch` is just `r`.
