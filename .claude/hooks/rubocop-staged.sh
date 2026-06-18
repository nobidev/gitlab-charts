#!/usr/bin/env bash
#
# Claude Code PreToolUse hook (matcher: Bash, filter: "git commit*").
#
# Before a commit is created, run RuboCop against the Ruby files that are
# staged for that commit. If RuboCop reports offenses, the commit is blocked
# (exit 2) and the offense report is fed back to Claude so it can autocorrect
# or fix the offenses and re-stage before committing again.
#
# The hook is intentionally conservative: if there are no staged Ruby files,
# or the Ruby/Bundler toolchain is not usable in the current environment, it
# exits 0 and lets the commit proceed instead of wedging unrelated work.
#
# Exit codes:
#   0  nothing to check / RuboCop clean / toolchain unavailable (commit allowed)
#   2  RuboCop reported offenses (commit blocked; stderr returned to Claude)

set -u

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0

# Only Ruby-relevant files that are staged (added/copied/modified).
files=$(git diff --cached --name-only --diff-filter=ACM \
  | grep -E '\.(rb|rake)$|(^|/)(Gemfile|Rakefile|Dangerfile)$') || true
[ -z "$files" ] && exit 0

command -v bundle >/dev/null 2>&1 || exit 0

# Make sure the Ruby/Bundler toolchain actually works here. A missing or
# mismatched Ruby (for example a version pinned in .tool-versions that is not
# installed locally) must not block commits on an unrelated environment issue.
if ! bundle exec ruby -e 'exit 0' >/dev/null 2>&1; then
  echo "RuboCop pre-commit hook skipped: Ruby/Bundler toolchain unavailable in this environment." >&2
  exit 0
fi

# shellcheck disable=SC2086  # staged paths are newline-separated and space-free
output=$(bundle exec rubocop --force-exclusion --no-server $files 2>&1)
status=$?

[ "$status" -eq 0 ] && exit 0

if [ "$status" -eq 1 ]; then
  printf '%s\n\n' "$output" >&2
  echo 'RuboCop found offenses in staged Ruby files. Run "bundle exec rubocop --autocorrect" on them (or fix them manually), re-stage, then commit again.' >&2
  exit 2
fi

# RuboCop crashed or was mis-configured (exit code >= 2): surface the output
# but do not block the commit on a tooling failure.
printf 'RuboCop could not complete (exit %s); commit not blocked:\n%s\n' "$status" "$output" >&2
exit 0
