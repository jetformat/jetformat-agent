#!/usr/bin/env bash
# Static checks for the Jetformat skill and plugin manifests.
set -eu
cd "$(dirname "$0")/.."
fail() { echo "check: $*" >&2; exit 1; }

skill=skills/jetformat/SKILL.md
[ -f "$skill" ] || fail "missing $skill"
grep -q '^name: jetformat$' "$skill" || fail "skill name"
grep -q 'Do not parse DOCX/PPTX/XLSX yourself' "$skill" || fail "anti-parsing rule"
grep -qi 'closed-source' "$skill" || fail "must say closed-source"
! grep -q 'open source' "$skill" || fail "must not claim open source"
! grep -Eq 'jetformat convert|office-to-pdf' "$skill" || fail "convert was removed from the CLI"
if grep -qi 'mcp' "$skill"; then grep -qi 'no mcp' "$skill" || fail "must not send agents to MCP"; fi

for manifest in .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.json .agents/plugins/marketplace.json; do
  node -e 'JSON.parse(require("fs").readFileSync(process.argv[1]))' "$manifest" || fail "invalid JSON $manifest"
done
[ "$(node -p 'require("./.claude-plugin/plugin.json").name')" = jetformat ] || fail "claude plugin name"
[ "$(node -p 'require("./plugin.json").name')" = jetformat ] || fail "codex plugin name"
[ "$(node -p 'require("./.claude-plugin/plugin.json").version')" = "$(node -p 'require("./plugin.json").version')" ] || fail "versions differ"
[ "$(wc -w < README.md)" -ge 40 ] || fail "README under 40 words"
[ -f LICENSE ] || fail "missing LICENSE"
find . -name .DS_Store -not -path './.git/*' | grep -q . && fail ".DS_Store in plugin"
echo "check: ok"
