#!/usr/bin/env bash
# Heuristic surface detector for the is-my-library-agent-friendly skill.
# Prints likely core/api/cli/ui surfaces for a repo. Verify every hit by
# hand before scoring the rubric; this only points, it doesn't decide.
set -uo pipefail

root="${1:-.}"
cd "$root"

excludes=(--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build)

echo "== cli =="
if [ -f package.json ]; then
  grep -q '"bin"' package.json && echo "root package.json has a bin field"
  if grep -q '"bin"' package.json && command -v node >/dev/null 2>&1; then
    node -e '
      const pkg = require("./package.json");
      const bin = pkg.bin;
      const paths = typeof bin === "string" ? [bin] : Object.values(bin || {});
      const fs = require("fs");
      for (const p of paths) {
        console.log(fs.existsSync(p)
          ? "  bin target exists: " + p
          : "  bin target MISSING (build first, or this is unrunnable from a fresh clone): " + p);
      }
    ' 2>/dev/null
  fi
fi
find . -path "*/node_modules" -prune -o -maxdepth 4 -name package.json -print 2>/dev/null \
  | xargs grep -l '"bin"' 2>/dev/null | sed 's/^/workspace package with a bin field: /'
find . -path "*/node_modules" -prune -o -maxdepth 4 -name "Cargo.toml" -print 2>/dev/null \
  | xargs grep -l '^\[\[bin\]\]' 2>/dev/null | sed 's/^/Cargo bin target: /'
[ -f pyproject.toml ] && grep -qE 'console_scripts|\[project\.scripts\]' pyproject.toml && echo "pyproject.toml declares console_scripts / [project.scripts]"
find . -path "*/node_modules" -prune -o -maxdepth 3 -type d -iname "cmd" -print 2>/dev/null | sed 's/^/Go cmd dir: /'

echo "== api =="
if [ -f package.json ]; then
  grep -qE '"(main|module|exports|types)"' package.json && echo "root package.json declares main/module/exports/types"
  if grep -q '"files"' package.json && ! grep -q '"exports"' package.json; then
    echo "package.json ships a \"files\" list but has no \"exports\" map -- subpath imports (docs, examples) may not resolve; check rubric row 10"
  fi
fi
find . -path "*/node_modules" -prune -o -maxdepth 3 -name "__init__.py" -print 2>/dev/null | sed -n '1p' | sed 's/^/Python package: /'
[ -f Cargo.toml ] && grep -q '\[lib\]' Cargo.toml && echo "Cargo.toml declares [lib]"

echo "== ui =="
[ -f package.json ] && grep -qE '"(react|vue|svelte|@angular/core)"' package.json && echo "UI framework dependency in root package.json"
grep -rl "createElement\|useState\|<canvas\|OffscreenCanvas" "${excludes[@]}" --include="*.ts" --include="*.tsx" --include="*.js" . 2>/dev/null | sed -n '1,3p'
echo "(a library can also emit style/layout data with no framework dependency at all -- this heuristic is blind to that; check by hand)"

echo "== mcp =="
# Don't assume the official SDK: a hand-rolled JSON-RPC-over-stdio server
# with no "@modelcontextprotocol/sdk" dependency anywhere is still an mcp
# surface, so check protocol vocabulary and path/filename separately.
grep -rl "@modelcontextprotocol/sdk\|StdioServerTransport\|modelcontextprotocol" "${excludes[@]}" --include="*.json" --include="*.ts" --include="*.js" --include="*.py" . 2>/dev/null | sed -n '1,5p' | sed 's/^/MCP SDK or transport reference: /'
grep -rl "\"tools/list\"\|\"tools/call\"\|tools/list\|tools/call\|protocolVersion" "${excludes[@]}" --include="*.ts" --include="*.js" --include="*.py" . 2>/dev/null | sed -n '1,5p' | sed 's/^/hand-rolled MCP protocol vocabulary (tools\/list, tools\/call, protocolVersion): /'
find . -path "*/node_modules" -prune -o \( -iname "*mcp*" -type d \) -print 2>/dev/null | sed -n '1,5p' | sed 's/^/directory with "mcp" in the name: /'
find . -path "*/node_modules" -prune -o -iname "*mcp*server*" -type f -print 2>/dev/null | sed -n '1,5p' | sed 's/^/MCP-named file: /'

echo "== headless-testability signals =="
find . -path "*/node_modules" -prune -o -maxdepth 3 -name package.json -print 2>/dev/null \
  | xargs grep -l "playwright\|puppeteer\|jsdom" 2>/dev/null | sed 's/^/browser test dependency: /'
grep -rli "mock.*adapter\|headless\|xvfb" "${excludes[@]}" --include="*.md" . 2>/dev/null | sed -n '1,3p' | sed 's/^/headless mention: /'

echo
echo "Heuristic only. Confirm each surface by actually running the corresponding entry point (see SKILL.md Step 1)."
