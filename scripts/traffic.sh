#!/usr/bin/env bash
# Live traffic monitor: sends a batch of requests to the "web" Service every
# second (from inside the cluster, so kube-proxy load-balances across ALL pods)
# and prints which version answered and how many requests failed.
set -euo pipefail
NS=${NS:-demo}
BATCH=${BATCH:-20}

kubectl -n "$NS" delete pod traffic --ignore-not-found --wait=true >/dev/null 2>&1 || true
exec kubectl -n "$NS" run traffic --rm -i --restart=Never --quiet \
  --image=curlimages/curl:8.11.1 --command -- sh -c "
  while true; do
    out=''
    for i in \$(seq $BATCH); do
      out=\"\$out \$(curl -s -o /dev/null -m 2 -D - http://web:8080/ | tr -d '\r' |
        awk '/^HTTP/{c=\$2} tolower(\$1)==\"x-app-version:\"{v=\$2} END{print v\":\"c}')\"
    done
    printf '%s  ' \"\$(date +%H:%M:%S)\"
    echo \$out | tr ' ' '\n' | sort | uniq -c |
      awk '{split(\$2,a,\":\"); tag=(a[2]==\"200\")?\"OK \":\"ERR\"; printf \"%s %s x%-3s  \", a[1], tag, \$1} END{print \"\"}'
    sleep 1
  done"
