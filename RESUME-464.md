# RESUME — mlx-serve localization sweep (scratch branch)

This file exists ONLY on `wip/mlxserve-464-sweep` (fork). It must never be
committed to a PR branch.

## What this run is

Fix ddalcu/mlx-serve PR #464 (branch `i18n/zh-hans-copy`) for the recurrent
review finding — a producer interpolates a localizable sentence BEFORE the
catalog lookup runs, so the format key can never match — then bring #462, #463
and #464 current by rebasing each onto the current `origin/main`.

Repo clone: `/Users/li/work/mlx-serve` (origin = ddalcu/mlx-serve,
fork = LXD-8/mlx-serve). `gh` needs
`/Users/li/Library/Application Support/CherryStudio/Toolchain/mise/shims` on PATH.
Main clone is on branch `i18n/zh-hans-copy` (when not on this scratch branch).
Tree is CLEAN as of this note. No rebase in progress. This note was updated
AFTER all three PR branches were force-pushed and the bot reply was posted —
see "Final state" below; the earlier "Remaining work" list is complete.

## Final state (all pushed, all green)

- PR #464 `i18n/zh-hans-copy` -> `51f5cf59bbc35d833eb24ce113eb39239abd8d12`
  (force-pushed with lease `i18n/zh-hans-copy:1c40f849…`).
- PR #463 `i18n/appkit-dialogs` -> `4b94b6ad46ced87308e180bf7f82dbd0c8d35dd7`
  (force-pushed with lease `i18n/appkit-dialogs:53f4316d…`).
- PR #462 `feat/in-app-language-switcher` ->
  `a29c2f49f8c158b4c1b8933ae37d4d81e73968e6`
  (force-pushed with lease `feat/in-app-language-switcher:c7050291…`).
- Bot reply posted: https://github.com/ddalcu/mlx-serve/pull/464#issuecomment-5740455914
- Coordinator caught an overclaim in that reply ("a guard for the class").
  Corrected by PATCHing the same comment in place (id 5740455914, no new
  comment). It now states: the tightened test rejects interpolated literals
  reaching a *lookup* helper and stops a consumer regressing back to a lookup,
  but it does NOT guard the verbatim shape (a producer that skips
  `L10n.format` for a consumer that renders verbatim) because those consumers
  are no longer detected as lookup helpers — that shape is currently unguarded.
  Reproduced: reverting only `ChatView.swift` fileChip's call site to
  `"PDF · \(pdf.text.count) chars"` and running the filtered test passes 7/7.
- PR #464 body also corrected (no overclaim was present, but it was stale):
  base line now says rebased/4 ahead, catalog count 1670, follow-up commit and
  the unguarded shape named, checklist item reworded to "no new source-scan
  tests; one grandfathered one was tightened".
- No new source-scanning guard was built (CONTRIBUTING forbids it; the
  verbatim shape needs a data-vs-copy allow-list — separate decision).
- Fail-before proof done: the modified LocalizationTests test fails on
  `1c40f849` (flags `fileChip` "PDF · \(…) chars" / "Video · \(…) frames") and
  passes on `51f5cf5`. Pre-fix worktree was removed.
- Remaining: none in-repo. Only the final report to the coordinator.

## Verified tips (GitHub API / git ls-remote)

- `origin/main` = `3a1ff57a84ce2d7227242981cb2b094bf697c7b9`
- PR #462 head (remote, pre-rebase) = `c7050291c1468838cc45c14c62fb7fe834e81705`
- PR #463 head (remote, pre-rebase) = `53f4316dfd3659301fbb32860155365fb62553c4`
- PR #464 head (remote, pre-rebase) = `1c40f849e526718d9f4fde5e3981bb03d636048f`

## Local, rebased (NOT pushed as of this note)

- #464 `i18n/zh-hans-copy` = `51f5cf5` (local; remote still 1c40f849)
  - one new signed commit on top of the 3 existing branch commits, rebased onto
    `3a1ff57`; app/ content of the pre-existing commits byte-identical to
    1c40f849 (only main's Zig-only commit differs).
  - GREEN: `swift test --no-parallel` 3551 tests, 26 skipped, 0 failures
    (both before and after rebase).
- #463 `i18n/appkit-dialogs` = `4b94b6a` (local; remote still 53f4316)
  - rebased onto `3a1ff57`; app/ content identical to 53f4316.
  - GREEN: 3551 tests, 26 skipped, 0 failures.
- #462 `ms-462-rebase` (local branch name; PR branch is
  `feat/in-app-language-switcher`) = `a29c2f4` (remote still c7050291)
  - rebased onto `3a1ff57`; app/ content identical to c7050291.
  - GREEN: 3560 tests, 26 skipped, 0 failures.
  - Note: local branch `feat/in-app-language-switcher` is checked out in a DIRTY
    worktree at `/private/tmp/ms-lang` (uncommitted edits to MLXServeApp.swift
    and SettingsView.swift). Do not disturb; the verified branch is
    `ms-462-rebase`.

## What #464's fix commit changes

Producer formats, consumer renders resolved text:
- `ChatView.swift` fileChip PDF/Video/Audio -> `L10n.format(...)`; `fileChip`
  renders `Text(detail)` verbatim.
- `SettingsView.swift` "Installed version — v%@" and "MLX Core v%@ is available"
  rows build titles with `L10n.format`.
- `AgentsWindow.swift` delete-confirm title and voice-menu "%@ (Settings)".
- `H3PromptExamples.swift` two "start with “%@”" hints.
- `ModelRowActions.swift` mlxServe delete message.
- `BenchmarkView.swift` context-too-small `runError`.
- Catalog: +"%@ (Settings)", +"Audio · %.1fs"; "This model is serving …"
  corrected `%lld` -> `%@` (producers pass `ContextSizeDisplay.formatTokens`,
  a String; verified with a `LocalizedStringKey` probe that String -> `%@`).
- `Tests/MLXCoreTests/LocalizationTests.swift`: the existing
  `testEveryLiteralReachingALookupHelperIsTranslated` no longer skips
  interpolated literals, so a caller that builds the sentence before the lookup
  is now caught.

## Remaining work (numbered)

1. Prove the modified test fails on the pre-fix head. Safe method that does NOT
   discard VCS data (a `git checkout <old> -- …` was blocked by the built-in
   guard): create a worktree `git worktree add -d /tmp/ms-prefix 1c40f849`,
   copy `app/Tests/MLXCoreTests/LocalizationTests.swift` from `i18n/zh-hans-copy`
   into it, then from `/tmp/ms-prefix/app`:
   `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk swift test
   --no-parallel --filter testEveryLiteralReachingALookupHelperIsTranslated`
   -> expected FAIL with `fileChip` interpolated literals. Remove the worktree
   afterwards.
2. Push the three PR branches, each with an explicit per-branch lease sha read
   from `git ls-remote fork refs/heads/<branch>` IMMEDIATELY before:
   - `git push fork i18n/zh-hans-copy:i18n/zh-hans-copy --force-with-lease=i18n/zh-hans-copy:1c40f849e526718d9f4fde5e3981bb03d636048f`
   - `git push fork ms-462-rebase:feat/in-app-language-switcher --force-with-lease=feat/in-app-language-switcher:c7050291c1468838cc45c14c62fb7fe834e81705`
   - `git push fork i18n/appkit-dialogs:i18n/appkit-dialogs --force-with-lease=i18n/appkit-dialogs:53f4316dfd3659301fbb32860155365fb62553c4`
   Re-read each lease sha right before its push; do not reuse these stale shas.
3. Reply IN-THREAD to the bot's review on PR #464 describing the systemic sweep
   and what was fixed, naming commit `51f5cf5` (rebase will change it; update).
   Use the GitHub API to find the review comment id, then
   `gh api repos/ddalcu/mlx-serve/pulls/464/comments/<id>/replies -f body=...`.
4. Report: full site enumeration with verdicts, file:line, reply text, per-branch
   rebase result + new head sha, verification command output, blockers.

## Exact verification commands

```
cd /Users/li/work/mlx-serve/app
SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk swift test --no-parallel
```

Catalog structure check (count / duplicates / sorted by code point / placeholder
arity) and the literal-`L10n`-key coverage check were run as ad-hoc Python over
`app/Sources/MLXServe/Resources/zh-Hans.lproj/Localizable.strings`; results:
1670 entries, no duplicate keys, 0 unsorted pairs, 0 placeholder mismatches,
0 missing literal L10n keys.
