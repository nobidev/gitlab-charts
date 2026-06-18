#!/usr/bin/env bash
#
# Claude Code PreToolUse hook (matcher: Bash).
#
# When Claude is about to run a command that creates a commit, run RuboCop
# against the Ruby files staged for that commit. If RuboCop reports offenses
# the commit is blocked (exit 2) and the report is returned to Claude so it
# can autocorrect or fix the offenses and re-stage before committing again.
#
# Why detect `git commit` here instead of with a settings-level filter:
# a prefix filter such as "Bash(git commit*)" only matches the START of the
# command string, so a compound command like `git add -A && git commit -m ...`
# (which starts with `git add`) would silently bypass the hook. This script
# receives the full command on stdin and inspects each segment (split on the
# shell operators &&, ||, ;, |), so chained and `git -C <path> commit` forms
# are covered. Plumbing subcommands such as `git commit-graph` and
# `git commit-tree` are intentionally NOT treated as commits.
#
# Enforcement: this check runs for every commit form. The one exception is an
# explicit `git commit --no-verify`, which bypasses it (mirroring git's own
# hook-bypass convention). Note that `--no-verify` only skips git hooks; this
# Claude Code hook honours the flag deliberately so there is an escape hatch.
#
# The hook is conservative: it is a no-op for non-commit commands and when no
# Ruby files are staged, and it does not block commits when the Ruby/Bundler
# toolchain is unavailable locally.
#
# Exit codes:
#   0  not a commit / nothing to check / RuboCop clean / toolchain unavailable
#   2  RuboCop reported offenses (commit blocked; stderr returned to Claude)

set -u

# --- Extract the command Claude is about to run from the hook payload. -------
payload=$(cat 2>/dev/null || true)
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  cmd=$payload   # no jq: fall back to scanning the raw payload
fi
[ -z "${cmd:-}" ] && exit 0

# --- Does any segment of the command invoke `git commit`? --------------------
# Strip parentheses (subshells) and split on &&, ||, ;, | and newlines.
segments=$(printf '%s' "$cmd" | sed -E 's/[()]//g; s/(&&|\|\||[;|])/\n/g')
is_commit=0
while IFS= read -r seg; do
  seg=$(printf '%s' "$seg" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
  [ -z "$seg" ] && continue
  # First token is `git` and `commit` appears as a whole word (so `commit-graph`
  # and `commit-tree` do not match).
  if [ "$(printf '%s' "$seg" | awk '{print $1}')" = "git" ] \
     && printf '%s' "$seg" | grep -Eq '(^|[[:space:]])commit([[:space:]]|$)'; then
    is_commit=1
    break
  fi
done <<EOF
$segments
EOF
[ "$is_commit" -eq 0 ] && exit 0

# Explicit opt-out: `git commit --no-verify` bypasses the check.
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])--no-verify([[:space:]]|$)'; then
  echo "RuboCop pre-commit hook skipped: --no-verify requested." >&2
  exit 0
fi

# --- Lint the staged Ruby files. ---------------------------------------------
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0

# Collect Ruby-relevant staged files (added/copied/modified) into an array so
# paths are passed to RuboCop individually and safely, even if one contains a
# space. A read-loop is used instead of `mapfile` for Bash 3.2 compatibility.
files=()
while IFS= read -r f; do
  [ -n "$f" ] && files+=("$f")
done < <(git diff --cached --name-only --diff-filter=ACM \
  | grep -E '\.(rb|rake)$|(^|/)(Gemfile|Rakefile|Dangerfile)$')
[ ${#files[@]} -eq 0 ] && exit 0

command -v bundle >/dev/null 2>&1 || exit 0

# Make sure the Ruby/Bundler toolchain actually works here. A missing or
# mismatched Ruby (for example a version pinned in .tool-versions that is not
# installed locally) must not block commits on an unrelated environment issue.
if ! bundle exec ruby -e 'exit 0' >/dev/null 2>&1; then
  echo "RuboCop pre-commit hook skipped: Ruby/Bundler toolchain unavailable in this environment." >&2
  exit 0
fi

# `--` terminates options so a path beginning with `-` is never read as a flag.
output=$(bundle exec rubocop --force-exclusion --no-server -- "${files[@]}" 2>&1)
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
