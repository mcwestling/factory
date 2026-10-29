#!/bin/sh
# Self-check for factory-verify: sh skills/do-factory-setup/factory-verify.test.sh
set -eu

script="$(cd "$(dirname "$0")" && pwd)/factory-verify"
tmp=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 1' HUP INT TERM
fail() { echo "FAIL: $*" >&2; exit 1; }

# Ignore the caller's git configuration and identity.
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.invalid
git init -q "$tmp/repo with spaces"
cd "$tmp/repo with spaces"
mkdir -p .factory packages/api-schema apps/ios
cat > .factory/verify.toml <<'EOF'
# Cross-app triggers select checks in file order.
version = 1

[checks.ios-contract]
run = "exit 0"
paths = ["packages/api-schema/**", "apps/ios/**"]

[checks.everything]
run = "exit 0"
paths = ["**"] # Also covers root files.
EOF
echo original > packages/api-schema/schema.txt
git add .
git commit -qm base
base=$(git rev-parse HEAD)
echo changed >> packages/api-schema/schema.txt
git commit -qam schema
head=$(git rev-parse HEAD)
expected="{\"base\":\"$base\",\"head\":\"$head\",\"checks\":[\"ios-contract\",\"everything\"]}"
actual=$(cd apps/ios && "$script" plan --base "$base" --head "$head")
[ "$actual" = "$expected" ] || fail "cross-app and everything selection: $actual"
echo "ok: plan uses cross-app triggers, file order and the repo root"

cat > .factory/verify.toml <<'EOF'
version = 1
[checks.root]
run = "test -d .factory && printf '%s\\n' root"
paths = ["**"]
[checks.fails]
run = "printf '%s\\n' first; exit 7"
paths = ["**"]
[checks.last]
run = "printf '%s\\n' last"
paths = ["**"]
EOF
[ "$(cd apps/ios && "$script" run root)" = root ] || fail "run must use the repo root"
status=0
"$script" run fails > "$tmp/out" || status=$?
[ "$status" -eq 7 ] || fail "run must preserve exit status 7, got $status"
status=0
"$script" run --all > "$tmp/out" || status=$?
[ "$status" -ne 0 ] || fail "run --all must fail when a check fails"
expected='root
PASS root
first
FAIL fails
last
PASS last'
[ "$(cat "$tmp/out")" = "$expected" ] || fail "run --all must continue in file order"
if "$script" run missing > "$tmp/out" 2> "$tmp/err"; then fail "unknown check must fail"; fi
grep -q missing "$tmp/err" || fail "unknown check error must name the check"
echo "ok: run preserves exit status; run --all reports and continues after failure"

cat > .factory/verify.toml <<'EOF'
version = 1
[checks.unrelated]
run = "exit 0"
paths = ["apps/ios/**"]
EOF
expected="{\"base\":\"$base\",\"head\":\"$head\",\"checks\":[]}"
[ "$("$script" plan --base "$base" --head "$head")" = "$expected" ] || fail "uncovered change"
cat >> .factory/verify.toml <<'EOF'
[checks.everything]
run = "exit 0"
paths = ["**"]
EOF
echo root > root.txt
git add root.txt
git commit -qm root
head=$(git rev-parse HEAD)
expected="{\"base\":\"$base\",\"head\":\"$head\",\"checks\":[\"everything\"]}"
[ "$("$script" plan --base "$base" --head "$head")" = "$expected" ] || fail "** must cover root files"
expected="{\"base\":\"$head\",\"head\":\"$head\",\"checks\":[]}"
[ "$("$script" plan --base "$head" --head "$head")" = "$expected" ] || fail "unchanged tree"
echo "ok: uncovered and unchanged changes select nothing; ** covers root files"

# A base-only commit must not affect the head-side three-dot diff.
git checkout -qb other "$base"
echo other > apps/ios/base-only.txt
git add apps/ios/base-only.txt
git commit -qm other
diverged=$(git rev-parse HEAD)
expected="{\"base\":\"$diverged\",\"head\":\"$head\",\"checks\":[\"everything\"]}"
[ "$("$script" plan --base "$diverged" --head "$head")" = "$expected" ] || fail "plan must use merge-base diff"
echo "ok: plan uses a three-dot diff on diverged branches"

expect_bad() {
  line=$1
  cat > .factory/verify.toml
  if "$script" run --all > "$tmp/out" 2> "$tmp/err"; then fail "accepted invalid contract: $2"; fi
  grep -q "^\.factory/verify.toml:$line:" "$tmp/err" || fail "missing file and line for $2: $(cat "$tmp/err")"
  [ ! -s "$tmp/out" ] || fail "invalid contract must not run checks: $2"
}
expect_bad 1 version <<'EOF'
version = 2
EOF
expect_bad 1 missing-version <<'EOF'
# no version
EOF
expect_bad 2 duplicate-version <<'EOF'
version = 1
version = 1
EOF
expect_bad 5 unknown-key <<'EOF'
version = 1
[checks.good]
run = "echo must-not-run"
paths = ["**"]
timeout = 5
EOF
expect_bad 2 invalid-name <<'EOF'
version = 1
[checks.Bad_Name]
EOF
expect_bad 5 duplicate-name <<'EOF'
version = 1
[checks.same]
run = "exit 0"
paths = ["**"]
[checks.same]
EOF
expect_bad 2 missing-paths <<'EOF'
version = 1
[checks.missing]
run = "echo must-not-run"
EOF
expect_bad 2 missing-run <<'EOF'
version = 1
[checks.missing]
paths = ["**"]
EOF
expect_bad 4 duplicate-run <<'EOF'
version = 1
[checks.duplicate]
run = "exit 0"
run = "exit 1"
paths = ["**"]
EOF
expect_bad 5 duplicate-paths <<'EOF'
version = 1
[checks.duplicate]
run = "exit 0"
paths = ["**"]
paths = ["apps/**"]
EOF
expect_bad 4 empty-paths <<'EOF'
version = 1
[checks.empty]
run = "exit 0"
paths = []
EOF
expect_bad 4 empty-path <<'EOF'
version = 1
[checks.empty]
run = "exit 0"
paths = [""]
EOF
expect_bad 3 multiline-string <<'EOF'
version = 1
[checks.multiline]
run = "echo
hi"
paths = ["**"]
EOF
expect_bad 4 multiline-array <<'EOF'
version = 1
[checks.multiline]
run = "exit 0"
paths = [
"**"]
EOF
expect_bad 3 triple-quotes <<'EOF'
version = 1
[checks.multiline]
run = """echo hi"""
paths = ["**"]
EOF
expect_bad 3 literal-string <<'EOF'
version = 1
[checks.literal]
run = 'exit 0'
paths = ["**"]
EOF
expect_bad 3 unknown-escape <<'EOF'
version = 1
[checks.escape]
run = "echo \q"
paths = ["**"]
EOF
expect_bad 2 unknown-table <<'EOF'
version = 1
[other]
EOF
expect_bad 2 field-outside-table <<'EOF'
version = 1
run = "exit 0"
EOF
expect_bad 4 missing-comma <<'EOF'
version = 1
[checks.array]
run = "exit 0"
paths = ["apps/**" "packages/**"]
EOF
echo "ok: unsupported syntax fails with file and line before running any check"

expect_bad 3 unicode-escape <<'EOF'
version = 1
[checks.escape]
run = "echo \u0061"
paths = ["**"]
EOF

# Quotes, comments and shell syntax in paths are data, never shell code.
cat > .factory/verify.toml <<'EOF'
version = 1 # A comment after a value.
[checks.quoted] # A comment after a table.
run = "printf '%s\\n' \"it's # literal\"; printf '%s' '\\n'; # shell comment"
paths = ["odd dir/it's # $(touch injected) [x].txt", "unused/**",]
EOF
expected="it's # literal
\n"
[ "$("$script" run quoted)" = "$expected" ] || fail "string escapes or quoted #"
mkdir -p 'odd dir'
# Use a literal apostrophe and a filename matching git glob [x].
echo data > "odd dir/it's # \$(touch injected) x.txt"
git add 'odd dir'
git commit -qm quoted-path
quoted_head=$(git rev-parse HEAD)
expected="{\"base\":\"$diverged\",\"head\":\"$quoted_head\",\"checks\":[\"quoted\"]}"
[ "$("$script" plan --base "$diverged" --head "$quoted_head")" = "$expected" ] || fail "git globs and literal shell syntax"
[ ! -e injected ] || fail "planning must not execute path contents"
echo "ok: string escapes, comments, trailing commas and shell quoting"

printf 'version = 1\n[checks.tab]\nrun = "printf '\''a\tb'\''"\npaths = ["**"]\n' > .factory/verify.toml
[ "$("$script" run tab)" = "$(printf 'a\tb')" ] || fail "literal tabs are allowed in TOML strings"
echo "ok: literal tabs in one-line strings"

cat > .factory/verify.toml <<'EOF'
version = 1
[checks.escapes]
run = "printf '%s' '\b\t\n\f\r'"
paths = ["**"]
EOF
[ "$("$script" run escapes)" = "$(printf '\b\t\n\f\r')" ] || fail "common control-character escapes"
echo "ok: common control-character escapes"

expect_bad 1 empty-file <<'EOF'
EOF

printf 'version = 1\r\n[checks.pass]\r\npaths = ["**"]\r\nrun = "exit 0"' > .factory/verify.toml
[ "$("$script" run --all)" = 'PASS pass' ] || fail "CRLF, reversed fields or missing final newline"
printf 'version = 1\n' > .factory/verify.toml
[ -z "$("$script" run --all)" ] || fail "empty contract should run no checks"
expected="{\"base\":\"$base\",\"head\":\"$head\",\"checks\":[]}"
[ "$("$script" plan --base "$base" --head "$head")" = "$expected" ] || fail "empty contract should plan no checks"
echo "ok: CRLF, either field order, no final newline and zero checks"

expect_usage() {
  status=0
  (cd "$tmp" && "$script" "$@") > "$tmp/out" 2> "$tmp/err" || status=$?
  [ "$status" -eq 2 ] || fail "usage should exit 2 for: $*"
  grep -q Usage "$tmp/err" || fail "usage message missing for: $*"
}
expect_usage
expect_usage unknown
expect_usage plan
expect_usage plan --base "$base"
expect_usage run
expect_usage run --all extra
if "$script" plan --base --help --head "$head" > "$tmp/out" 2> "$tmp/err"; then fail "invalid SHA accepted"; fi
[ ! -s "$tmp/out" ] || fail "invalid SHA must not print a plan"
if "$script" plan --base deadbeef --head "$head" > "$tmp/out" 2> "$tmp/err"; then fail "missing commit accepted"; fi
rm .factory/verify.toml
if "$script" run --all > "$tmp/out" 2> "$tmp/err"; then fail "missing contract accepted"; fi
grep -q '.factory/verify.toml' "$tmp/err" || fail "missing contract error must name the file"
echo "ok: usage, bad revisions and missing contracts fail cleanly"
echo "all factory-verify checks passed"
