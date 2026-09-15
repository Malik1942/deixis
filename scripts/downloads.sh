#!/bin/zsh
# v0.6 R50: how many times each release asset was downloaded, newest release first.
set -euo pipefail
gh api repos/Malik1942/deixis/releases --paginate \
  --jq '.[] | .tag_name as $t | .published_at[:10] as $d | .assets[] | "\($t)\t\($d)\t\(.name)\t\(.download_count)"' \
  | column -t -s $'\t'
