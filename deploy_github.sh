#!/usr/bin/env bash
# Deploy D:/ppp/blog to https://github.com/menghf/menghf.github.io
# Usage: bash deploy_github.sh <GITHUB_TOKEN>
set -e

TOKEN="$1"
if [ -z "$TOKEN" ]; then
  echo "ERROR: pass a GitHub token as the first argument"
  exit 1
fi

OWNER=menghf
REPO=menghf.github.io
API=https://api.github.com
AUTH=(-H "Authorization: Bearer ${TOKEN}" -H "Accept: application/vnd.github+json")
cd /d/ppp/blog

echo "==> 1. ensure repository exists"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${AUTH[@]}" "${API}/repos/${OWNER}/${REPO}")
if [ "$STATUS" = "404" ]; then
  curl -s "${AUTH[@]}" -X POST "${API}/user/repos" \
    -d "{\"name\":\"${REPO}\",\"description\":\"Personal blog built with Astro\",\"homepage\":\"https://menghf.github.io\",\"private\":false,\"auto_init\":false}" \
    > /dev/null
  echo "    repository created"
elif [ "$STATUS" = "200" ]; then
  echo "    repository already exists"
else
  echo "    unexpected status ${STATUS} when checking repo"
  exit 1
fi

echo "==> 2. commit and push source"
if [ ! -d .git ]; then
  git init -b main
fi
git config user.email "menghf@users.noreply.github.com"
git config user.name "menghf"
git add -A
git commit -m "chore: initialize devolio blog site" --allow-empty
git remote remove origin 2>/dev/null || true
git remote add origin "https://${OWNER}:${TOKEN}@github.com/${OWNER}/${REPO}.git"
git push -u origin main --force

echo "==> 3. enable GitHub Pages (GitHub Actions source)"
curl -s "${AUTH[@]}" -X POST "${API}/repos/${OWNER}/${REPO}/pages" \
  -d '{"build_type":"workflow","source":{"branch":"main","path":"/"}}' | head -c 400
echo ""
curl -s "${AUTH[@]}" -X PUT "${API}/repos/${OWNER}/${REPO}/pages" \
  -d '{"build_type":"workflow","source":{"branch":"main","path":"/"}}' | head -c 400
echo ""

echo "==> 4. done"
echo "    repo   : https://github.com/${OWNER}/${REPO}"
echo "    actions: https://github.com/${OWNER}/${REPO}/actions"
echo "    site   : https://menghf.github.io"
