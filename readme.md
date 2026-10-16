# homebrew-tap

A personal Homebrew tap distributing six developer tools that each ship with a
different, language-specific install path, plus a source build of the third-party
[disktree](https://github.com/tobi/disktree) app. See [design-doc.md](docs/design-doc.md) for
the formula design and the reasoning behind it, and
[formula-readiness.md](docs/formula-readiness.md) for current status and open work.

## Install

```bash
brew tap will-wright-eng/tap
brew install disktree g3 hc loch mdcsv mgmt sosig
```

Or without tapping first:

```bash
brew install will-wright-eng/tap/hc
```

## Tools

| Formula | Description | Upstream |
|---------|-------------|----------|
| `disktree` | Treemap for finding and removing what fills your disk (macOS app + CLI) | [tobi/disktree](https://github.com/tobi/disktree) |
| `g3` | Object storage CLI over GitHub Gists, speaking aws-cli vocabulary | [will-wright-eng/gists3](https://github.com/will-wright-eng/gists3) |
| `hc` | Hot/cold codebase analysis: git churn crossed with file complexity | [will-wright-eng/hc](https://github.com/will-wright-eng/hc) |
| `loch` | Per-commit LOC history via gix and tokei, without a working tree | [will-wright-eng/loch](https://github.com/will-wright-eng/loch) |
| `mdcsv` | Convert between markdown tables and CSV | [will-wright-eng/mdcsv](https://github.com/will-wright-eng/mdcsv) |
| `mgmt` | Command-line interface to search and manage media assets in S3 | [will-wright-eng/media-mgmt-cli](https://github.com/will-wright-eng/media-mgmt-cli) |
| `sosig` | Analyze GitHub repositories and calculate social-signal metrics | [will-wright-eng/social-signals](https://github.com/will-wright-eng/social-signals) |

Each formula pins a release; `brew livecheck --tap will-wright-eng/tap` compares those
pins with the latest upstream releases.

## CI

- `audit.yml` runs `brew audit --strict`, `brew install --build-from-source`, and
  `brew test` for each formula changed by a push to `main` or a PR.
- `livecheck.yml` runs `brew livecheck` monthly and opens a `livecheck/bump` PR for
  any formula behind upstream.
- Dependabot keeps the SHA-pinned actions current.

## Development

```bash
brew tap will-wright-eng/tap "$(pwd)"
brew audit --strict will-wright-eng/tap/<name>
brew install --build-from-source will-wright-eng/tap/<name>
brew test will-wright-eng/tap/<name>
brew livecheck will-wright-eng/tap/<name>
brew uninstall <name>
```

Every formula builds from source, so nothing here downloads an unsigned binary and
the macOS Gatekeeper deprecation that motivated this tap does not apply.

## References

- [design-doc.md](docs/design-doc.md): formula design by language
- [formula-readiness.md](docs/formula-readiness.md): status, tasks, and upstream checks
- [disktree-formula-spec.md](docs/disktree-formula-spec.md): the `disktree` formula design
- [Homebrew discussion #6482](https://github.com/orgs/Homebrew/discussions/6482): the Gatekeeper/custom-tap thread
- [Homebrew Taps documentation](https://docs.brew.sh/Taps)
