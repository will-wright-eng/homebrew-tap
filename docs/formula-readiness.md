# Formula Readiness

## Summary

All seven formulas are pinned to their latest upstream release, pass `brew audit
--strict`, `brew install --build-from-source`, and `brew test` in CI (run
`38828427234`, 2026-10-16, the first run after the repo rename), and declare a license
that matches upstream. `sosig` now installs the PyPI sdist under `GPL-3.0-or-later`
(T2.1 + T5.5).

The open work is automation, upstream housekeeping, and repo hygiene:

- **Livecheck can't open PRs (T6.1).** Both runs so far (2026-10-01 scheduled,
  2026-10-13 manual) bumped formulas and pushed `livecheck/bump`, then failed at
  `gh pr create` because the repo doesn't allow Actions to create PRs. PRs #3 and #6
  were opened by hand.
- **`mgmt`:** upstream's latest GitHub release never reached PyPI (T3.5).
- **`social-signals`:** its GitHub release tag doesn't match the PyPI version (T5.6).
- **Immutable releases** are on only in `hc` (T6.7).
- **`disktree`:** CI is green; three manual checks remain (T7.1).
- **Smaller items:** `g3` reports no version (T4.7), `mgmt`'s test doesn't check its
  version (T4.8), and a stale `feat/formula` branch remains (T6.8).

Upstream state was last checked on 2026-10-16 (see
[Upstream Check](#upstream-check-2026-10-16)).

This document doesn't track version numbers. The formulas are the source of truth, and
`brew livecheck --tap will-wright-eng/tap` compares them with upstream.

A formula is **valid** when:

1. its `url` points at an immutable upstream artifact (a tag or a published package),
2. its `license` stanza matches what the upstream repo actually declares, and
3. it passes `brew audit --strict`, `brew install --build-from-source`, and `brew test` in CI.

## Current State

| Formula | Upstream repo | Source | Upstream license | Formula `license` | Status |
| ------- | ------------- | ------ | ---------------- | ----------------- | ------ |
| `g3` | `gists3` | GitHub release tag | MIT | `MIT` | **Valid**; no version reporting (T4.7) |
| `hc` | `hc` | GitHub release tag | GPL-3.0 + or-later notice | `GPL-3.0-or-later` | **Valid** |
| `loch` | `loch` | GitHub release tag | GPL-3.0 + or-later notice | `GPL-3.0-or-later` | **Valid** |
| `mdcsv` | `mdcsv` | GitHub release tag | GPL-3.0 + or-later notice | `GPL-3.0-or-later` | **Valid** |
| `sosig` | `social-signals` | PyPI sdist | `License-Expression: GPL-3.0-or-later` | `GPL-3.0-or-later` | **Valid** |
| `mgmt` | `media-mgmt-cli` | PyPI sdist | GPL-3.0, `GPLv3+` classifier | `GPL-3.0-or-later` | **Valid**; upstream release unpublished on PyPI (T3.5) |
| `disktree` | `tobi/disktree` (third party) | GitHub release tag | MIT | `MIT` | **Valid**; manual checks remain (T7.1) |

### CI

| Workflow | Trigger | State |
| -------- | ------- | ----- |
| `audit.yml` | push to `main` or PR touching `Formula/**` (changed formulae only), manual dispatch | All seven pass on `main` |
| `livecheck.yml` | 1st of each month 14:00 UTC, manual dispatch | Bumps and pushes `livecheck/bump`, then fails at PR creation until T6.1 |

`livecheck.yml` runs `brew livecheck --tap will-wright-eng/tap --json`, then
`.github/scripts/bump_formula.py` rewrites `url` and `sha256` for each outdated formula
(and regenerates Python resources). The workflow pushes a `livecheck/bump` branch,
opens or updates a PR, and dispatches `audit.yml` for the bumped formulae against that
branch, because pushes made with `GITHUB_TOKEN` don't trigger other workflows. A
livecheck error fails the job.

## Remaining Work

In suggested order. Details are under [Tasks](#tasks).

| # | Task | Where | Blocked by |
| - | ---- | ----- | ---------- |
| 1 | **T6.1** Allow Actions to create PRs | repo settings | — |
| 2 | **T6.7** Enable immutable releases in `loch`, `gists3`, `mdcsv` | those repos | — |
| 3 | **T7.1** Finish the `disktree` manual checks | local | — |
| 4 | **T6.8** Delete the stale `feat/formula` branch | this repo | — |
| 5 | **T4.8** Assert `mgmt --version` in its test | this repo | — |
| 6 | **T3.5** Publish `mgmt` to PyPI, then bump the formula | `media-mgmt-cli`, then this repo | — |
| 7 | **T5.6** Fix the `social-signals` release tag and author email | `social-signals` | — |
| 8 | **T6.7** Enable immutable releases in `media-mgmt-cli`, `social-signals` | those repos | 6, 7 |
| 9 | **T4.7** Add a version variable to `g3`, then assert it in the test | `gists3`, then this repo | — |

## Critical Path

```text
Phase 1  Tap fixes              ─── done
Phase 2  License decisions      ─── done
Phase 3  Upstream licenses      ─── done except T3.5
Phase 4  Releases + checksums   ─── done except T4.7, T4.8
Phase 5  social-signals rework  ─── done except T5.6
Phase 6  Repo hardening         ─── remaining: T6.1 (unblocks livecheck PRs), T6.7, T6.8
Phase 7  Third-party formulas   ─── remaining: T7.1 manual checks
```

## Decisions

### D1: `sosig` license

**Resolved: `GPL-3.0-or-later`.** This follows the default in
[design-doc.md](design-doc.md#licenses): GPL for tools authored here,
with `gists3`'s MIT as the exception. `social-signals` `7c97b25` adds the GPL-3.0
LICENSE and sets `license = "GPL-3.0-or-later"`, and `Formula/sosig.rb` declares it.

### D2: GPL "or later" grant

The GPL text on its own does not grant "or later"; that has to be stated separately.
**Resolved: add an explicit notice upstream** rather than switching formulas to
`GPL-3.0-only`. Adopted in `loch`, `mdcsv`, and `hc`. `mgmt` is backed by its `GPLv3+`
classifier and SPDX `license` field; `sosig` by its SPDX `license` field.

```markdown
## License

Copyright (C) 2026 <copyright holder>

Licensed under the GNU General Public License, version 3 or (at your option) any
later version. See [LICENSE](LICENSE).
```

## Tasks

### Phase 1: Tap fixes (this repo)

- [x] **T1.1 Fix CI.** `setup-homebrew` moved from `@master` to a SHA-pinned release,
      and the manual `brew tap <path>` step was removed, because `setup-homebrew`
      already symlinks a `homebrew-*` checkout into `Library/Taps`.
- [x] **T1.2 Declare `sosig`'s runtime dependency on `gh`.**
- [x] **T1.3 Fix the broken README link.**

### Phase 2: License decisions

- [x] **T2.1** `Formula/sosig.rb` declares `GPL-3.0-or-later`, done with T5.5.
- [x] **T2.2** D2 resolved with Option A; no formula change needed.

### Phase 3: Upstream licenses

- [x] **T3.1 `loch`:** LICENSE, `Cargo.toml` `license`, and README with the D2 notice (`09c43bb`).
- [x] **T3.2 `mdcsv`:** LICENSE and D2 notice (`5b1fada`).
- [x] **T3.3 `social-signals`:** LICENSE and PEP 639 `license` (`7c97b25`).
- [x] **T3.4 `hc`:** D2 notice (`a8d76db`).
- [ ] **T3.5 `media-mgmt-cli`:** `ccbef60` fixes the license metadata and author email,
      and a `v0.12.0` GitHub release exists, but `pyproject.toml` at that tag still says
      `version = "0.11.0"`. The publish tried to re-upload `0.11.0` and PyPI rejected
      it, so PyPI's latest is still `0.11.0`. To finish:
      1. bump `version` to `0.12.1` and cut a `v0.12.1` release (don't move the
         `v0.12.0` tag; see T6.7),
      2. confirm the publish workflow uploads `0.12.1`,
      3. let livecheck open the bump PR, or bump by hand; either way, add
         `depends_on "cmake" => :build` for `awscrt` (see [Watch List](#watch-list)).

### Phase 4: Releases and checksums

- [x] **T4.1–T4.3** `gists3`, `loch`, `mdcsv` tagged their first releases.
- [x] **T4.4** Checksums pinned and verified against the published tarballs.
- [x] **T4.5 Refresh the docs.** `readme.md` and `design-doc.md` no longer carry version
      numbers, pinned checksums, or copies of formula and workflow files, so a bump
      needs no doc change.
- [x] **T4.6 Move `hc` to the release with the or-later notice** (livecheck PR #3).
- [ ] **T4.7 Make `g3` report its version.** The formula builds with
      `ldflags: :goreleaser`, but `gists3` declares no `version` variable in `cmd/g3`,
      so nothing is stamped and there is no `--version`. Add the variable (and a flag
      or subcommand to print it) upstream, then assert it in the formula's test the
      way `hc` does.
- [ ] **T4.8 Assert `mgmt --version` in its test.** `mgmt` exposes `--version`; the
      test only checks `--help`.

### Phase 5: `social-signals` restructure and republish

- [x] **T5.1** Package moved to the repo root (`7c97b25`).
- [x] **T5.2** `pip` removed from `dependencies`.
- [x] **T5.3** Database no longer created on import.
- [x] **T5.4** Fixed sdist published to PyPI from `c9a2d66`; it has no `..` paths and
      declares `License-Expression: GPL-3.0-or-later`.
- [x] **T5.5 Switch `Formula/sosig.rb` to the sdist pattern.** `url` points at the
      sdist, `install` is `virtualenv_install_with_resources`, `livecheck` uses
      `url :stable` / `strategy :pypi`, and the resources were regenerated with
      `brew update-python-resources` (dropping `greenlet`, which SQLAlchemy no longer
      requires). `depends_on "rust" => :build` stays for `pydantic-core`. Verified in
      a scratch tap: `brew audit --strict --online --new` passes,
      `brew install --build-from-source` completes in 1m24s, and `brew test` passes.
- [ ] **T5.6 Upstream housekeeping (non-blocking):**
  - The latest GitHub release is tagged `v0.4.0`, but PyPI's latest is `0.3.1`. The
    formula's livecheck reads PyPI, so it isn't affected. Either publish `0.4.0` to
    PyPI so they match, or replace the release with a `v0.3.1` one.
  - Fix the `authors` email typo (`will.wright.engineeering@gmail.com`, three e's) in
    `pyproject.toml`; it is still present on `main` and in the published metadata.
  - Delete the leftover local `sosig/` directory (untracked `.venv` and `.coverage`);
    not re-verified, since it is untracked.

### Phase 6: Repo hardening (this repo's settings)

The repo is public. Controls in place:

- a `main` ruleset that blocks deletion and force-pushes and requires a PR with one approval
  (admins can bypass)
- default workflow permissions set to `read`
- only GitHub-owned actions and `Homebrew/actions/*` may run, and SHA pinning is required
- workflow runs from every outside contributor need approval
- Dependabot alerts, security updates, and private vulnerability reporting
- branches deleted automatically after merge
- secret scanning with push protection
- no repository secrets
- auto-merge disabled
- every action pinned to a commit SHA, with Dependabot keeping the pins current

`livecheck.yml` checks out with `persist-credentials: false` and passes the token only
to the push, so `brew` and the bump script never see it.

- [ ] **T6.1 Allow Actions to create PRs.** Required for `livecheck.yml`; both runs so
      far failed with `GitHub Actions is not permitted to create or approve pull
      requests`. The same setting also lets Actions approve PRs, so no workflow with
      `pull-requests: write` may run on untrusted input (no `pull_request_target`).

  ```bash
  gh api -X PUT repos/will-wright-eng/homebrew-tap/actions/permissions/workflow \
    -f default_workflow_permissions=read -F can_approve_pull_request_reviews=true
  ```

- [x] **T6.2 Restrict which actions can run, and require SHA pinning.**
- [x] **T6.3 Require approval before running workflows from any outside contributor.**
- [x] **T6.4 Enable Dependabot alerts, security updates, and private vulnerability reporting.**
- [x] **T6.5 Delete branches automatically after merge.**
- [x] **T6.6 Merge the Dependabot PRs** (#2, #5).
- [ ] **T6.7 Enable immutable releases in the six upstream repos.** Every formula pins
      the checksum of a release artifact, so a moved tag breaks installs. `hc` has it.
      `loch`, `gists3`, and `mdcsv` can turn it on now; `media-mgmt-cli` and
      `social-signals` should wait for T3.5 and T5.6, which may still need to replace
      releases.

  ```bash
  for r in loch gists3 mdcsv; do
    gh api -X PUT repos/will-wright-eng/$r/immutable-releases
  done
  ```

- [ ] **T6.8 Delete the stale `feat/formula` branch.** Its one unmerged commit
      (`3383e45`, 2026-06-26, "Add hc and mgmt formulas, Makefile, audit CI, and docs")
      predates everything on `main` and is superseded by it.

  ```bash
  git push origin --delete feat/formula
  ```

Keep bot PRs manual-merge only. The required approval is the only human check between
an upstream release and users of the tap.

Not recommended:

- **Required status checks on the ruleset:** `audit.yml` is path-filtered, so PRs that
  don't touch `Formula/**` would wait forever for checks that never run.
- **CODEOWNERS:** it adds nothing with a single maintainer.

### Phase 7: Third-party formulas

- [ ] **T7.1 `disktree`.** `audit.yml` passes, and `codesign --verify` reports the
      installed `disktree.app` valid and satisfying its designated requirement.
      Remaining manual checks from
      [disktree-formula-spec.md](disktree-formula-spec.md#testing): the app opening
      from Finder via the caveats' `~/Applications` symlink, a `--HEAD` build, and a
      clean uninstall. T6.7 does not apply: the upstream repo is not ours.

## Upstream Check (2026-10-16)

| Repo | Result |
| ---- | ------ |
| `gists3` | Formula on the latest release. Immutable releases off. |
| `hc` | Formula on the latest release. Immutable releases on. |
| `loch` | Formula on the latest release. Immutable releases off. |
| `mdcsv` | Formula on the latest release. Immutable releases off. |
| `social-signals` | Formula on PyPI's latest. GitHub's latest release is tagged `v0.4.0`; author email typo still present. |
| `media-mgmt-cli` | Formula on PyPI's latest (`0.11.0`). GitHub's latest release is `v0.12.0`, which never reached PyPI. |
| `tobi/disktree` | Formula on the latest release. |

`brew livecheck --tap will-wright-eng/tap` reports a version for all seven with no
errors and nothing outdated. `brew audit --strict --online --tap will-wright-eng/tap`
reports no problems.

## Verification

Run this for each formula locally before pushing:

```bash
brew tap will-wright-eng/tap "$(pwd)"
brew audit --strict will-wright-eng/tap/<name>
brew install --build-from-source will-wright-eng/tap/<name>
brew test will-wright-eng/tap/<name>
brew livecheck will-wright-eng/tap/<name>
brew uninstall <name>
```

If the tap is already installed from GitHub, test in a throwaway tap instead, and use
the fully qualified name throughout, since the formula exists in both taps:

```bash
brew tap-new --no-git will-wright-eng/scratch
cp Formula/<name>.rb "$(brew --repo will-wright-eng/scratch)/Formula/"
brew audit --strict --online will-wright-eng/scratch/<name>
brew install --build-from-source will-wright-eng/scratch/<name>
brew test will-wright-eng/scratch/<name>
brew uninstall will-wright-eng/scratch/<name>
brew untap will-wright-eng/scratch
```

`brew install` reports `Failed to fix install linkage` with a
`TapFormulaAmbiguityError` here; the keg is installed and the error is only the
post-install step looking the formula up by its short name.

Everything is done when:

- [x] all seven `audit.yml` matrix jobs pass on `main`,
- [x] `brew livecheck` reports a version for all seven, without errors,
- [x] no formula is behind upstream,
- [x] no formula's `license` stanza claims more than its upstream repo declares, and
- [ ] `livecheck.yml` has run on schedule and opened a PR that passes `audit.yml` (T6.1).

## Watch List

These don't block anything now, but will need action later.

- **`mgmt` and `awscrt`.** Upstream `pyproject.toml` lists `botocore[crt]`, which the
  version on PyPI does not. Once T3.5's release reaches PyPI, it will pull in the
  compiled `awscrt` package, and the bump will need `depends_on "cmake" => :build`
  in addition to the regenerated resources. The livecheck bot regenerates resources but
  won't add build dependencies, so expect its first `mgmt` PR to fail `audit.yml` until
  that line is added.
- **Python resource cooldown.** `bump_formula.py` passes
  `--ignore-main-package-cooldown` so a just-published release can be bumped, but the
  formula's dependencies still respect Homebrew's release cooldown.

## References

- [design-doc.md](design-doc.md): formula design and the reasoning behind each choice
- [Homebrew License Guidelines](https://docs.brew.sh/License-Guidelines)
- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Homebrew Python for Formula Authors](https://docs.brew.sh/Python-for-Formula-Authors)
- [Homebrew `brew livecheck`](https://docs.brew.sh/Brew-Livecheck): the `GithubLatest` strategy reads GitHub releases
- [Homebrew/actions](https://github.com/Homebrew/actions): `setup-homebrew`
- [GitHub: Triggering a workflow from a workflow](https://docs.github.com/en/actions/using-workflows/triggering-a-workflow#triggering-a-workflow-from-a-workflow): `GITHUB_TOKEN` events don't start new runs, except `workflow_dispatch`
- [GitHub: Immutable releases](https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/immutable-releases)
- [zizmor audits](https://docs.zizmor.sh/audits/): `artipacked` and credential persistence
- [GNU: How to Use GNU Licenses for Your Own Software](https://www.gnu.org/licenses/gpl-howto.html): the "or later" notice
- [SPDX License List](https://spdx.org/licenses/): `GPL-3.0-or-later`, `GPL-3.0-only`, `MIT`
- [PEP 639: Licensing metadata in core metadata](https://peps.python.org/pep-0639/): `license` as an SPDX expression
- [Cargo manifest: `license` field](https://doc.rust-lang.org/cargo/reference/manifest.html#the-license-and-license-file-fields)
