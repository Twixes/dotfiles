#!/usr/bin/env bash
# Paginated PR fetch for mm-today. Emits one JSON object: {prs: [...], truncated: bool}
# Usage: ./fetch-prs.sh 'is:pr is:open org:PostHog author:Twixes'
set -euo pipefail
Q="${1:?usage: fetch-prs.sh <github search query>}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GQL="$DIR/pr-triage.graphql"
after=""; page=0; tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
while :; do
  page=$((page+1))
  if [ -z "$after" ]; then
    gh api graphql -F query=@"$GQL" -f q="$Q" > "$tmp/p$page.json"
  else
    gh api graphql -F query=@"$GQL" -f q="$Q" -f after="$after" > "$tmp/p$page.json"
  fi
  if grep -q '"errors"' "$tmp/p$page.json"; then
    echo "GraphQL error on page $page:" >&2; head -c 400 "$tmp/p$page.json" >&2; exit 1
  fi
  next=$(python3 -c "import json,sys;d=json.load(open('$tmp/p$page.json'));print(d['data']['search']['pageInfo']['hasNextPage'])")
  after=$(python3 -c "import json,sys;d=json.load(open('$tmp/p$page.json'));print(d['data']['search']['pageInfo']['endCursor'] or '')")
  [ "$next" = "True" ] || break
  # GitHub search caps at 1000 results; 40 pages of 25 is well past any sane queue
  [ "$page" -ge 40 ] && break
done
python3 - "$tmp" <<'PY'
import json,sys,glob,os
prs=[]; count=None
for f in sorted(glob.glob(os.path.join(sys.argv[1],'p*.json')), key=lambda p:int(''.join(c for c in os.path.basename(p) if c.isdigit()))):
    s=json.load(open(f))['data']['search']
    count=s['issueCount']; prs.extend(s['nodes'])
prs=[p for p in prs if p]
print(json.dumps({"prs":prs,"issueCount":count,"fetched":len(prs),
                  "truncated": count is not None and len(prs)<count}))
PY
