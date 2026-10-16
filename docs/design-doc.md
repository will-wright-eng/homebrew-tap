# homebrew-tap: Design Document

## Overview

A personal Homebrew tap (`will-wright-eng/homebrew-tap`) distributing six developer
tools that today each have a different, language-specific install path — `go install`,
`cargo build`, `uv tool install`, or `git clone && make install`. The tap collapses
those into one command per tool, with pinned versions and auditable checksums. A
seventh formula, `disktree`, packages a third-party GUI app; see
[Third-party formula: `disktree`](#third-party-formula-disktree).

Scope is deliberately a **tap**, not submissions to `homebrew-core`. Core requires
notability thresholds (maintained, stable, widely used) these tools do not meet, and
core rejects HEAD-only and unversioned formulas outright. A tap has no such gate.

The Gatekeeper deprecation mentioned in `readme.md`
(`does not pass the macOS Gatekeeper check`) applies to **casks** shipping signed
`.app`/binary artifacts, not to formulas. Every formula here builds from source on the
user's machine, Python sdists included, so Gatekeeper never sees a downloaded
executable. `Homebrew/deprecate_disable.rb` exposes `:fails_gatekeeper_check`
only as a cask deprecation reason, and the audit that enforces it lives in
`Library/Homebrew/cask/audit.rb`. This tap is unaffected.

Every formula is pinned to an immutable upstream artifact. This document records the
design and leaves version numbers to the formulas themselves;
[formula-readiness.md](formula-readiness.md) tracks current status and open work.

---

## Tool Inventory

Facts below were read from each repository and from PyPI, not assumed.

| Tool | Repo | Language | Binary | License | Release source |
|------|------|----------|--------|---------|----------------|
| `hc` | `will-wright-eng/hc` | Go | `hc` | GPL-3.0-or-later | GitHub release tag |
| `loch` | `will-wright-eng/loch` | Rust | `loch` | GPL-3.0-or-later | GitHub release tag |
| `g3` | `will-wright-eng/gists3` | Go | `g3` | MIT | GitHub release tag |
| `sosig` | `will-wright-eng/social-signals` | Python | `sosig` | GPL-3.0-or-later | PyPI `sosig` sdist |
| `mgmt` | `will-wright-eng/media-mgmt-cli` | Python | `mgmt` | GPL-3.0-or-later | PyPI `mgmt` sdist |
| `mdcsv` | `will-wright-eng/mdcsv` | Go | `mdcsv` | GPL-3.0-or-later | GitHub release tag |
| `disktree` | `tobi/disktree` (third party) | Rust | `disktree` (+ `disktree.app`) | MIT | GitHub release tag |

Every tool has a tag or published package and a LICENSE file; see
[Upstream Prerequisites](#upstream-prerequisites) for how they got there.

### Name collisions

Every proposed formula name was checked against the Homebrew API. `hc`, `loch`, `g3`,
`gists3`, `sosig`, `mgmt`, and `mdcsv` all return `404` for both
`formulae.brew.sh/api/formula/<name>.json` and the cask equivalent — no collisions in
core. Within a tap, a colliding name is still installable via the fully-qualified
`will-wright-eng/tap/<name>`, so this is a convenience concern rather than a blocker.

Note the `gists3` repo ships **two** commands under `cmd/`: `g3` (the real CLI) and
`example`. The formula is named `g3` after the binary, not after the repo, and builds
only `./cmd/g3`. No `gists3` alias is provided: the command users type is `g3`, and a
second name is one more thing to keep in sync for no discoverability gain.

---

## Repository Structure

```
homebrew-tap/
├── Formula/
│   ├── disktree.rb
│   ├── g3.rb
│   ├── hc.rb
│   ├── loch.rb
│   ├── mdcsv.rb
│   ├── mgmt.rb
│   └── sosig.rb
├── .github/
│   ├── dependabot.yml
│   ├── scripts/
│   │   └── bump_formula.py
│   └── workflows/
│       ├── audit.yml
│       └── livecheck.yml
├── docs/
│   ├── design-doc.md
│   ├── disktree-formula-spec.md
│   └── formula-readiness.md
└── readme.md
```

Homebrew discovers formulas from `.rb` files under `Formula/`. The class name is the
CamelCased filename (`g3.rb` → `class G3`), and the default install target is
`bin/<formula name>` — which is why the formula name must match the intended command.

---

## Formula Design by Language

### Go formulas: `hc`, `g3`, `mdcsv`

Go is the simplest case. Homebrew provides `std_go_args`, which sets `-o bin/<name>`,
`-trimpath`, and the module flags. Homebrew's `go` must satisfy the `go` directive in
each repo's `go.mod`; check it when bumping to a release that raises the directive.

All three pass `ldflags: :goreleaser` to `std_go_args`, which injects `main.version`,
`main.commit`, `main.date`, and `main.builtBy`. A variable the program does not declare
is silently skipped, so the flag is harmless where it stamps nothing.

`std_go_args(ldflags:)` already prepends `-s -w` unless debug symbols are requested
(`formula.rb:2308` tests `ENV.debug_symbols?`, which `brew install --debug-symbols`
sets), so passing `ldflags: "-s -w"` duplicates them. Pass only the flags the project
actually needs.

#### `hc`

`hc` declares `version` and `commit` as `main`-package variables (`cmd/hc/main.go:25-28`)
and renders them through `Version: fmt.Sprintf("%s (%s)", version, commit)`
(`cmd/hc/main.go:102`). Built without ldflags it reports `dev (none)`. Homebrew's
`hc`'s own `.goreleaser.yaml` sets only `version` and `commit`, so `date` and `builtBy`
are skipped and the two that matter line up. That keeps `hc --version` truthful, and
the test asserts it. See [`Formula/hc.rb`](../Formula/hc.rb).

```ruby
  def install
    system "go", "build", *std_go_args(ldflags: :goreleaser), "./cmd/hc"
  end

  test do
    assert_match "Hot/Cold codebase analysis", shell_output("#{bin}/hc --help")
    assert_match version.to_s, shell_output("#{bin}/hc --version")
  end
```

The `sha256` in every GitHub-sourced formula is the checksum of the GitHub-generated
source archive for the tag, verified with `curl -sL <url> | shasum -a 256`. It is not
the checksum of a goreleaser release asset; those have their own checksums (published
in `checksums.txt`) and are only relevant if the tap ever switches to shipping prebuilt
binaries.

#### `mdcsv`

All code is in a single top-level `main.go`, so the build target is `.`, not `./cmd/...`.
`mdcsv --help` exits `0` and prints to stdout, and `mdcsv --version` reports the stamped
version. See [`Formula/mdcsv.rb`](../Formula/mdcsv.rb).

```ruby
  def install
    system "go", "build", *std_go_args(ldflags: :goreleaser), "."
  end

  test do
    assert_match "usage: mdcsv", shell_output("#{bin}/mdcsv --help")
    assert_match version.to_s, shell_output("#{bin}/mdcsv --version")
  end
```

#### `g3`

Two gotchas, both verified by running the built binary:

1. `g3` has no `--help` flag. `g3 --help` prints `g3: unknown command "--help"`,
   writes the usage text **to stderr**, and exits **2**. The same is true of `g3` with
   no arguments and of `g3 help`.
2. `shell_output(cmd)` asserts an exit status of `0` by default
   (`formula_assertions.rb:32`) and merges stderr into the captured output
   (`err: :err`). So the test must pass the expected status explicitly.

```ruby
  def install
    system "go", "build", *std_go_args(ldflags: :goreleaser), "./cmd/g3"
  end

  test do
    # g3 has no --help flag: usage goes to stderr with exit status 2.
    assert_match "usage: g3", shell_output("#{bin}/g3 2>&1", 2)
  end
```

`g3` declares no `version` variable, so the goreleaser ldflags stamp nothing yet and
the test cannot assert a version. Once upstream adds one, the test should check it the
way `hc`'s does. See [`Formula/g3.rb`](../Formula/g3.rb).

`g3` has zero dependencies beyond the Go standard library, so there is no `go.sum` to
vendor and the build is fully offline after the tarball is fetched.

---

### Rust formula: `loch`

Homebrew provides `std_cargo_args`, which expands to
`--jobs N --locked --root=#{prefix} --path=.` (`formula.rb:2219`). It also appends
`--offline`, but only for formulas that define their own `fetch` method; `loch` does
not, so the flag does not apply here. The `--locked` flag requires a committed
`Cargo.lock` — `loch` has one.

Two facts from `Cargo.toml` shape this formula:

- `rust-version` sets the minimum toolchain; Homebrew's `rust` must satisfy it, so
  check it when bumping.
- A comment in the manifest records that the crates.io name `loch` is squatted by a
  dormant 2019 crate. That only matters for `cargo install loch` from the registry;
  building from the GitHub tarball with `--path=.` bypasses crates.io entirely, and the
  produced binary is named `loch` because the package is. **No rename is needed for the
  tap.** If the crate is ever published as `loch-cli`, the formula keeps working
  unchanged as long as it keeps building from the git source.

```ruby
  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/loch --version")
    system bin/"loch", "--help"
  end
```

`loch` derives `clap::Parser` with `version`, so `--version` prints the `Cargo.toml`
version and `--help` exits `0`. See [`Formula/loch.rb`](../Formula/loch.rb).

`gix` and `tokei` are pinned to exact versions in `Cargo.toml` and pull a large
dependency tree, but the build parallelises well: about 30 seconds on an arm64 Mac. The
slowest formula in the tap is `sosig`, which compiles `pydantic-core` from Rust source.

---

### Python formulas: `mgmt` and `sosig`

Both use Homebrew's `Language::Python::Virtualenv`, which builds an isolated venv under
`libexec` and symlinks entry-point scripts into `bin`. Nothing touches the system Python.

Two non-obvious mechanics drive the design, both confirmed by reading
`Library/Homebrew/language/python.rb`:

- `virtualenv_install_with_resources` installs every `resource` block, then installs the
  **staged source root** (`buildpath`). It therefore assumes the main `url` is an sdist
  that unpacks to a buildable directory.
- Homebrew's `pip_install` runs pip with `--no-binary=:all:`, forcing *every* dependency
  to build from source. The flag itself comes from `std_pip_args`
  (`formula.rb:2347`), which `pip_install` reaches via its private `do_install`. Any
  dependency with a compiled extension needs its build toolchain declared as a
  formula-level `depends_on ... => :build`.

Both formulas pin a specific `python@3.x`. Moving to a later Python means editing the
`depends_on` line in each.

Both use the same shape: the main `url` is the PyPI sdist, `livecheck` uses
`url :stable` with `strategy :pypi`, and the body is a single call. See
[`Formula/mgmt.rb`](../Formula/mgmt.rb) and [`Formula/sosig.rb`](../Formula/sosig.rb).

```ruby
  livecheck do
    url :stable
    strategy :pypi
  end

  # resource blocks generated by `brew update-python-resources`

  def install
    virtualenv_install_with_resources
  end
```

The `url` and `sha256` are the published sdist values, read from the PyPI JSON API.

#### `mgmt`

`mgmt`'s PyPI sdist is well-formed — verified by extracting it and building it in a
clean venv, which produced a working `mgmt` binary whose `--help` exits `0`.

One discrepancy worth recording: the repo's `pyproject.toml` lists `botocore[crt]` as a
dependency, but the **published** metadata does not (`Requires-Dist` is only `boto3`,
`rich`, `typer`). `brew update-python-resources` reads published metadata, so the `crt`
extra — which pulls the compiled `awscrt` package — is not resolved. That keeps the
build free of a C/C++ extension. Once a release publishes with `botocore[crt]`, the
formula needs `depends_on "cmake" => :build`.

#### `sosig`

`sosig` depends on `sqlmodel` → `pydantic` → `pydantic-core`, which is written in Rust.
Because Homebrew's `pip_install` forces `--no-binary=:all:`, the prebuilt
`pydantic-core` wheel is ignored and it is compiled from source, so the formula declares
`depends_on "rust" => :build`. Without it the build fails with `Failed to build
'pydantic_core-…' when installing build dependencies`. Homebrew's own audit requires
`rust` be listed before `python@3.x`.

`sosig` shells out to the GitHub CLI at runtime, hence `depends_on "gh"`.

Early `sosig` releases shipped an sdist that could not be built: the package lived in a
subdirectory and its `pyproject.toml` pointed `readme` at `../README.md`, which `tar`
and hatchling both reject. The formula installed the wheel instead, which needed
`using: :nounzip`, a renamed copy of `cached_download`, a hand-written `livecheck`, and
`--package-name` for resource generation. Upstream moved the package to the repo root,
so the sdist builds and all of that is gone. If a future release regresses, the wheel
pattern is in this file's git history.

---

### Third-party formula: `disktree`

`disktree` is the tap's first formula for a tool not authored here, and its first GUI
app. It builds [tobi/disktree](https://github.com/tobi/disktree) from its release tag
with upstream's own bundler, `cargo xtask bundle`, which produces an ad-hoc signed
`target/bundle/disktree.app`. The formula installs that app into the keg and symlinks
`bin/disktree` to `disktree.app/Contents/MacOS/disktree`, mirroring upstream's
`make install`.

- It is a formula rather than a cask so the tap keeps shipping no downloaded binaries,
  and a locally built app carries no quarantine flag.
- `depends_on :macos`: Linux needs Vulkan/Wayland libraries and is out of scope.
- No Metal compiler is needed, because `gpui-kit` enables `runtime_shaders` on macOS.
  If that changes, the formula needs `depends_on xcode: :build`, and CI will not catch
  it because GitHub's macOS runners ship full Xcode.
- The ad-hoc signature changes every build, so Full Disk Access may need re-granting
  after upgrades; the caveats say so.
- Upstream's `rust-toolchain.toml` is ignored (Homebrew has no rustup); watch
  `rust-version` in its `Cargo.toml` when bumping.

The full design, test plan, and risks are in
[disktree-formula-spec.md](disktree-formula-spec.md).

---

## Upstream Prerequisites

A formula's `url` must point at an immutable artifact — a tag, a published package, or a
commit SHA — because a branch tarball's `sha256` changes on every push, breaking every
install. When the tap was first written, three tools had no tags and three had no
LICENSE file. All of these are now resolved upstream:

| Tool | Original blocker | Resolution |
|------|------------------|------------|
| `loch` | No tags/releases; no LICENSE | GPL-3.0 LICENSE with "or later" notice; first release tagged |
| `g3` | No tags/releases | First release tagged (MIT LICENSE was already present) |
| `mdcsv` | No tags/releases; no LICENSE | GPL-3.0 LICENSE with "or later" notice; first release tagged |
| `sosig` | No LICENSE; unbuildable sdist | GPL-3.0 LICENSE and PEP 639 `license`; buildable sdist published to PyPI |

Remaining upstream housekeeping is tracked in [formula-readiness.md](formula-readiness.md).

### Licenses

`brew audit --strict` does **not** fail a tap formula for a missing `license` stanza —
only for a non-SPDX or deprecated identifier. But a tool with no LICENSE file is "all
rights reserved" by default, and distributing it via a public tap invites users to
install code they have no license to use. A LICENSE comes before the tag.

GPL is the default for tools authored here; `gists3`'s MIT is the exception, not the
pattern. `hc`, `loch`, `mdcsv`, `mgmt`, and `sosig` are all `GPL-3.0-or-later`.

For the GPL tools, the correct SPDX identifier is `GPL-3.0-or-later`, not
`GPL-3.0-only`. The GPL text alone does not grant "or later", so each upstream README
carries an explicit "version 3 or (at your option) any later version" notice, or the
package metadata declares `GPL-3.0-or-later` directly. `GPL-3.0` (no suffix) is
deprecated in the SPDX list and should not be used — `brew audit --strict` rejects it.

### Interim option: pinned-commit URLs

If a tool ever needs to ship before its repo is tagged, a commit SHA is also immutable:

```ruby
url "https://github.com/will-wright-eng/<repo>/archive/<commit-sha>.tar.gz"
version "<version>"   # required: Homebrew cannot infer a version from a SHA URL
sha256 "<sha256 of that tarball>"
```

This was verified end to end for `mdcsv`, `g3`, and `loch` before they were tagged:
with a pinned-commit `url`/`version`/`sha256`, `brew audit --strict` passed, and
`brew install --build-from-source` plus `brew test` succeeded: `mdcsv` in 2s, `g3` in
3s, `loch` in 30s.

Tagging is still preferred — a `version` that is unrelated to any upstream marker is a
maintenance trap — and it is the route taken here: all three waited for their first
tags rather than shipping on pinned commits. Treat pinned commits as a bridge, not a
destination.

### `head` blocks

The five source-built formulas (`hc`, `loch`, `g3`, `mdcsv`, `disktree`) each include a `head`
stanza so `brew install --HEAD <tool>` tracks `main`. This is allowed in taps
(`formula_auditor.rb:875` only rejects *HEAD-only* formulas, and only for core). It
gives a supported way to install untagged work without compromising the stable,
checksummed path. The two Python formulas have no `head`: their `url` points at a
published PyPI artifact rather than a git remote.

---

## Description Strings

`brew audit` enforces rules on `desc` via `RuboCop::Cop::DescHelper`: ≤80 characters, no
leading article, starts with a capital, no trailing full stop, must not start with the
formula name, `command-line` must be hyphenated, no emoji. All seven were checked against
those rules:

| Formula | `desc` | Length |
|---------|--------|--------|
| `hc` | Hot/cold codebase analysis: git churn crossed with file complexity | 66 |
| `loch` | Per-commit LOC history via gix and tokei, without a working tree | 64 |
| `g3` | Object storage CLI over GitHub Gists, speaking aws-cli vocabulary | 65 |
| `sosig` | Analyze GitHub repositories and calculate social-signal metrics | 63 |
| `mgmt` | Command-line interface to search and manage media assets in S3 | 62 |
| `mdcsv` | Convert between markdown tables and CSV | 39 |
| `disktree` | Treemap for finding and removing what fills your disk | 53 |

Note `mgmt`'s upstream summary begins "An intuitive command line interface…", which
would trip three separate rules (leading article, unhyphenated "command line", and
length). The rewrite above is deliberate.

---

## Versioning Strategy

| Tool | Source of truth | Update procedure |
|------|----------------|------------------|
| `hc` | GitHub release tag | Bump `url` tag, recompute `sha256` |
| `loch` | GitHub release tag | Bump `url` tag, recompute `sha256` |
| `g3` | GitHub release tag | Bump `url` tag, recompute `sha256` |
| `mdcsv` | GitHub release tag | Bump `url` tag, recompute `sha256` |
| `disktree` | GitHub release tag | Bump `url` tag, recompute `sha256`; check upstream `rust-version` |
| `mgmt` | PyPI sdist | Bump `url`/`sha256`, re-run `brew update-python-resources` |
| `sosig` | PyPI sdist | Bump `url`/`sha256`, re-run `brew update-python-resources` |

No formula tracks a moving branch on its stable path. Every update is a deliberate,
reviewable commit — including the ones `livecheck.yml` proposes, which arrive as PRs
that still need a human approval.

Every formula also builds from source on the user's machine; none ship prebuilt
binaries. `hc` publishes goreleaser assets for darwin/linux × amd64/arm64, so a
binary-download formula (`on_macos`/`on_arm` blocks selecting the right asset) would
install in seconds instead of minutes — but that is also the point at which Gatekeeper
becomes relevant again, since an unsigned downloaded binary is exactly what the
deprecation in `readme.md` targets. Source builds sidestep it and keep every formula
uniform. Revisit if `loch`'s Rust build time becomes annoying.

### `livecheck`

Every formula carries a `livecheck` block so `brew livecheck` reports when the tap is
behind upstream. The five GitHub-sourced formulas use:

```ruby
livecheck do
  url :stable
  strategy :github_latest
end
```

`mgmt` and `sosig` use `url :stable` with `strategy :pypi`, which derives the project
name from the sdist filename. It would misread a wheel filename, so a formula that ever
falls back to a wheel needs a hand-written block naming the PyPI JSON URL.

These blocks also drive the automated bumps described under
[CI: Livecheck](#ci-livecheck).

---

## CI: Formula Audit

`audit.yml` audits, installs, and tests each changed formula on pushes to `main` and on
PRs (opened, synchronized, reopened) that touch `Formula/`, and on manual dispatch. Five
details matter:

- A `select` job diffs the event's base against its head and builds the matrix from the
  changed `Formula/*.rb` files, so a PR that bumps `hc` does not rebuild `sosig`. A
  change to `audit.yml` itself, or a diff base that cannot be resolved (new branch,
  force push), selects every formula. Manual dispatch takes an optional `formulae`
  input and audits everything when it is empty; `livecheck.yml` passes the formulae it
  bumped. The formula list is read from `Formula/`, so a new formula needs no workflow
  change.
- Pushes are limited to `main` so a PR branch is not audited twice, once for the push
  and once for the PR. Only PR runs cancel in progress: each `main` run audits only its
  own push, so cancelling one would leave its formulae unaudited.
- `setup-homebrew` symlinks a `homebrew-*` checkout into `Library/Taps`, so CI tests the
  committed formulas rather than whatever is published. A separate `brew tap <path>`
  step conflicts with that symlink and must not be added.
- Building `sosig` compiles `pydantic-core` from Rust source, which is slow. The job
  needs a generous timeout.
- Every action is pinned to a commit SHA, with the release in a trailing comment.
  Dependabot (`.github/dependabot.yml`) proposes grouped weekly bumps with a 7-day
  cooldown.

The workflow itself is [`.github/workflows/audit.yml`](../.github/workflows/audit.yml).
Each matrix job runs the same three steps against `will-wright-eng/tap/<formula>`:

```yaml
      - name: Audit
        run: brew audit --strict "$FORMULA"

      - name: Install
        run: brew install --build-from-source "$FORMULA"

      - name: Test
        run: brew test "$FORMULA"
```

A matrix is used rather than one job over all formulas so a single broken formula does
not mask the others, and so the slow Rust builds run in parallel with the fast Go ones.
`fail-fast: false` keeps the rest running after one failure.

`brew test-bot` is the alternative to hand-rolling audit/install/test. It is what
`homebrew-core` uses and it handles bottling, but it assumes core's PR conventions; the
explicit three steps above are easier to reason about for a personal tap.

---

## CI: Livecheck

`livecheck.yml` runs at 14:00 UTC on the 1st of each month, and on manual dispatch:

1. `brew livecheck --tap will-wright-eng/tap --json` writes every formula's current
   and latest version. A livecheck error does not stop the run; the bump script reports
   it after bumping the formulas that did resolve, and the job fails.
2. `.github/scripts/bump_formula.py` rewrites the top-level `url` and `sha256` of each
   outdated formula. GitHub archives are re-hashed after swapping the version in the
   URL; PyPI files are looked up in the PyPI JSON API. Formulas that include
   `Language::Python::Virtualenv` also get `brew update-python-resources`.
3. The changes are force-pushed to a `livecheck/bump` branch, and one PR is opened or
   updated with a conventional-commit title of the form
   `chore(<formulae>): bump <formula> to <version>, ...`.
4. The workflow dispatches `audit.yml` against that branch for the bumped formulae,
   because pushes made with `GITHUB_TOKEN` do not trigger other workflows, but
   `workflow_dispatch` does.

The job checks out with `persist-credentials: false` and passes the token only to the
push and `gh` steps, so `brew` and the bump script never see it. It needs
`contents: write`, `pull-requests: write`, and `actions: write`, and the repository
setting that lets Actions create PRs.

The bot changes only `url`, `sha256`, and resources. A new build dependency — such as
`cmake` if `mgmt` starts pulling in `awscrt` — still has to be added by hand, and the
PR's `audit.yml` run is what surfaces the need.

---

## Setup Checklist

Ongoing work lives in [formula-readiness.md](formula-readiness.md); this list records
the initial setup.

**One-time repo setup**
- [x] Add `Formula/` with the six original `.rb` files
- [x] Add `.github/workflows/audit.yml`, SHA-pinned, with Dependabot for actions
- [x] Add `.github/workflows/livecheck.yml` and `.github/scripts/bump_formula.py`
- [x] Expand `readme.md` with install instructions

**Formulas**
- [x] `Formula/hc.rb` — release tag pinned, `sha256` verified; installs and tests clean
- [x] `Formula/mgmt.rb` — PyPI sdist pinned; resources generated
- [x] `Formula/sosig.rb` — PyPI sdist pinned; resources generated
- [x] `loch` — GPL-3 LICENSE added, first release tagged, `sha256` pinned
- [x] `g3` — first release tagged, `sha256` pinned
- [x] `mdcsv` — GPL-3 LICENSE added, first release tagged, `sha256` pinned

**`social-signals` follow-ups**
- [x] Add a LICENSE file
- [x] Fix `readme = "../README.md"` and republish
- [x] Move `Formula/sosig.rb` to the sdist pattern with `license "GPL-3.0-or-later"`

**Per-formula verification loop**

```bash
brew tap will-wright-eng/tap "$(pwd)"
brew audit --strict will-wright-eng/tap/<name>
brew install --build-from-source will-wright-eng/tap/<name>
brew test will-wright-eng/tap/<name>
brew livecheck will-wright-eng/tap/<name>
brew uninstall <name>
```

If `brew audit` crashes with a vendored-gem `NoMethodError` rather than reporting
findings, the local gem bundle is stale. `brew install-bundler-gems --add-groups=audit`
repairs it.

---

## User-facing Install

```bash
brew tap will-wright-eng/tap
brew install disktree g3 hc loch mdcsv mgmt sosig
```

Or without tapping first:

```bash
brew install will-wright-eng/tap/hc
```

Note the tap is named `will-wright-eng/tap`: `brew tap` strips the `homebrew-` prefix
from the repository name `homebrew-tap`.

---

## Maintenance

When a new version of a tool is released, `livecheck.yml` opens the bump PR on its next
monthly run (or on manual dispatch). To bump by hand instead:

1. Update `url` to the new tag or sdist.
2. Recompute the checksum: `curl -sL <url> | shasum -a 256`.
3. For `mgmt`/`sosig`, re-run `brew update-python-resources`.
4. Open a PR — CI audits, installs, and tests before merge.
5. Merge to `main`. Users pick it up on the next `brew upgrade`.

`brew bump-formula-pr --url=<new-url> --sha256=<new-sha>` automates steps 1–2 and opens
the PR; `brew bump-python-resources-pr` does the same for the resource blocks.

---

## References

- [formula-readiness.md](formula-readiness.md) — current status, open tasks, upstream checks
- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Homebrew Python for Formula Authors](https://docs.brew.sh/Python-for-Formula-Authors)
- [Homebrew Taps documentation](https://docs.brew.sh/Taps)
- [Homebrew Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae) — why these belong in a tap, not core
- [Homebrew `brew livecheck` documentation](https://docs.brew.sh/Brew-Livecheck)
- [SPDX License List](https://spdx.org/licenses/) — `GPL-3.0-or-later`, `MIT`
- [Homebrew discussion #6482](https://github.com/orgs/Homebrew/discussions/6482) — the Gatekeeper/custom-tap thread in `readme.md`
- [Homebrew/actions](https://github.com/Homebrew/actions) — `setup-homebrew`
- [GitHub: Triggering a workflow from a workflow](https://docs.github.com/en/actions/using-workflows/triggering-a-workflow#triggering-a-workflow-from-a-workflow) — why `livecheck.yml` dispatches `audit.yml`
- Homebrew source consulted directly: `Library/Homebrew/formula.rb` (`std_go_args`, `std_cargo_args`, `std_pip_args`), `Library/Homebrew/language/python.rb` (`virtualenv_install_with_resources`, `pip_install`), `Library/Homebrew/formula_assertions.rb` (`shell_output`), `Library/Homebrew/rubocops/shared/desc_helper.rb`, `Library/Homebrew/utils/pypi.rb`, `Library/Homebrew/livecheck/strategy/pypi.rb`
