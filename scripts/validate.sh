#!/usr/bin/env bash
# =============================================================================
# validate.sh - リポジトリ内のファイルを静的に検証するスクリプト
#
# 実行するチェック(実AWS環境には一切接続しません):
#   1. シェルスクリプトの構文チェック(bash -n)
#   2. shellcheck(インストールされている場合のみ)
#   3. JSON の妥当性(python3 -m json.tool)
#   4. YAML の妥当性(PyYAML がある場合のみ)
#   5. Markdown の相対リンクが実在するファイルを指しているか
#   6. terraform fmt -check(terraform がインストールされている場合のみ)
#
# 使い方:
#   ./scripts/validate.sh          # リポジトリのルートで実行
# 終了コード: 0 = すべて成功、1 = いずれかのチェックが失敗
# =============================================================================
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

FAILED=0
pass() { echo "  ✅ $1"; }
fail() { echo "  ❌ $1"; FAILED=1; }
skip() { echo "  ⏭  $1"; }

echo "== 1. bash -n(シェル構文) =="
while IFS= read -r f; do
  if bash -n "$f" 2>/dev/null; then pass "$f"; else fail "$f"; fi
done < <(find . -name '*.sh' -not -path './.git/*' | sort)

echo "== 2. shellcheck =="
if command -v shellcheck >/dev/null 2>&1; then
  while IFS= read -r f; do
    # SC1090/SC1091: source する state ファイルは実行時に生成されるため除外
    if shellcheck -e SC1090,SC1091 "$f"; then pass "$f"; else fail "$f"; fi
  done < <(find . -name '*.sh' -not -path './.git/*' | sort)
else
  skip "shellcheck 未インストールのためスキップ"
fi

echo "== 3. JSON =="
while IFS= read -r f; do
  if python3 -m json.tool "$f" >/dev/null 2>&1; then pass "$f"; else fail "$f"; fi
done < <(find . -name '*.json' -not -path './.git/*' | sort)

echo "== 4. YAML =="
if python3 -c 'import yaml' 2>/dev/null; then
  while IFS= read -r f; do
    if python3 -c "import sys,yaml; yaml.safe_load(open(sys.argv[1]))" "$f" 2>/dev/null; then pass "$f"; else fail "$f"; fi
  done < <(find . \( -name '*.yml' -o -name '*.yaml' \) -not -path './.git/*' | sort)
else
  skip "PyYAML 未インストールのためスキップ"
fi

echo "== 5. Markdown 相対リンク =="
if python3 - <<'PY'
import os, re, sys
bad = []
for root, _, files in os.walk('.'):
    # テンプレート(プレースホルダのリンクを含む)は対象外
    if '/.git' in root or root.startswith('./evidence/templates'):
        continue
    for name in files:
        if not name.endswith('.md'):
            continue
        path = os.path.join(root, name)
        text = open(path, encoding='utf-8').read()
        for m in re.finditer(r'\]\(([^)]+)\)', text):
            target = m.group(1).split('#', 1)[0].strip()
            if not target or target.startswith(('http://', 'https://', 'mailto:')):
                continue
            if not os.path.exists(os.path.normpath(os.path.join(root, target))):
                bad.append((path, m.group(1)))
for p, t in bad:
    print(f"  ❌ {p}: {t}")
sys.exit(1 if bad else 0)
PY
then pass "すべての相対リンクが解決しました"; else fail "壊れたリンクがあります"; fi

echo "== 6. terraform fmt -check =="
if command -v terraform >/dev/null 2>&1; then
  if terraform fmt -check -recursive projects/06-iac-cicd/handson >/dev/null; then
    pass "terraform fmt"
  else
    fail "terraform fmt(terraform fmt -recursive で整形してください)"
  fi
else
  skip "terraform 未インストールのためスキップ"
fi

echo ""
if [[ "$FAILED" -eq 0 ]]; then
  echo "🎉 すべてのチェックに成功しました"
else
  echo "⚠️  失敗したチェックがあります。上の ❌ を確認してください"
fi
exit "$FAILED"
