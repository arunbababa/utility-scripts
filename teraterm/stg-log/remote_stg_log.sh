#!/bin/sh
set -eu

# This script runs on the app-operation host after the Tera Term macro logs in.
# It does not know any passwords. Tera Term handles SSH password prompts.

POD_FILE="/tmp/stg_log_pods.$$"

finish() {
  code=$?
  rm -f "$POD_FILE"
  echo
  echo "STG_LOG_AUTO_EXIT=$code"
}
trap finish EXIT

require_value() {
  name="$1"
  value="$2"

  if [ -z "$value" ]; then
    echo "Missing setting: $name" >&2
    exit 2
  fi

  case "$value" in
    \<*\>)
      echo "Placeholder is not configured: $name=$value" >&2
      exit 2
      ;;
  esac
}

# Values are passed from stg_log_auto.ttl through environment variables.
FRONT_NAMESPACE="${FRONT_NAMESPACE:-}"
BACK_NAMESPACE="${BACK_NAMESPACE:-}"
FRONT_POD_PATTERN="${FRONT_POD_PATTERN:-}"
BACK_POD_PATTERN="${BACK_POD_PATTERN:-}"
FRONT_LOG_DIR="${FRONT_LOG_DIR:-}"
BACK_LOG_DIR="${BACK_LOG_DIR:-}"
FRONT_LOG_GLOB="${FRONT_LOG_GLOB:-}"
BACK_LOG_GLOB="${BACK_LOG_GLOB:-}"
TAIL_LINES="${TAIL_LINES:-120}"

TARGET="${1:-front}"

case "$TARGET" in
  front)
    NS="$FRONT_NAMESPACE"
    POD_PATTERN="$FRONT_POD_PATTERN"
    LOG_DIR="$FRONT_LOG_DIR"
    LOG_GLOB="$FRONT_LOG_GLOB"
    ;;
  back)
    NS="$BACK_NAMESPACE"
    POD_PATTERN="$BACK_POD_PATTERN"
    LOG_DIR="$BACK_LOG_DIR"
    LOG_GLOB="$BACK_LOG_GLOB"
    ;;
  *)
    echo "TARGET must be front or back: $TARGET" >&2
    exit 2
    ;;
esac

require_value "namespace" "$NS"
require_value "pod pattern" "$POD_PATTERN"
require_value "log directory" "$LOG_DIR"
require_value "log glob" "$LOG_GLOB"

echo "== target = $TARGET"
echo "== namespace = $NS"
echo "== full pod list"
kubectl get pod -n "$NS" -o wide

# First narrow candidates by the front/back pod keyword.
# If the keyword does not match, fall back to all Running pods in the namespace.
kubectl get pod -n "$NS" -o wide --no-headers 2>/dev/null \
  | awk -v pat="$POD_PATTERN" '$1 ~ pat && $3 == "Running" { print }' \
  > "$POD_FILE"

if [ ! -s "$POD_FILE" ]; then
  echo "== no Running pod matched pattern: $POD_PATTERN"
  echo "== fallback: all Running pods"
  kubectl get pod -n "$NS" -o wide --no-headers 2>/dev/null \
    | awk '$3 == "Running" { print }' \
    > "$POD_FILE"
fi

if [ ! -s "$POD_FILE" ]; then
  echo "No Running pod found in namespace: $NS" >&2
  exit 3
fi

echo
echo "== candidate pods"
echo "No.  Pod name  Status  Node"
awk '{ printf "%2d  %-80s  %-10s  %s\n", NR, $1, $3, $7 }' "$POD_FILE"
echo
echo "Input pod number, exact pod name, or search keyword. Empty = 1"
printf 'POD_SELECT> '
IFS= read -r SELECT

if [ -z "$SELECT" ]; then
  SELECT=1
fi

# A numeric input selects the displayed number.
# A text input first tries exact pod name, then partial pod-name match.
case "$SELECT" in
  *[!0-9]*)
    POD="$(
      awk -v sel="$SELECT" \
        '$1 == sel { print $1; found=1; exit } END { if (!found) exit 1 }' \
        "$POD_FILE" 2>/dev/null || true
    )"

    if [ -z "$POD" ]; then
      MATCH_COUNT="$(
        awk -v sel="$SELECT" 'index($1, sel) > 0 { c++ } END { print c + 0 }' "$POD_FILE"
      )"

      if [ "$MATCH_COUNT" -eq 1 ]; then
        POD="$(awk -v sel="$SELECT" 'index($1, sel) > 0 { print $1; exit }' "$POD_FILE")"
      elif [ "$MATCH_COUNT" -gt 1 ]; then
        echo "Selection is ambiguous: $SELECT" >&2
        awk -v sel="$SELECT" 'index($1, sel) > 0 { printf "%2d  %s\n", NR, $1 }' "$POD_FILE" >&2
        exit 6
      else
        echo "No pod matched selection: $SELECT" >&2
        exit 7
      fi
    fi
    ;;
  *)
    POD="$(awk -v n="$SELECT" 'NR == n { print $1; exit }' "$POD_FILE")"
    if [ -z "$POD" ]; then
      echo "No pod at number: $SELECT" >&2
      exit 8
    fi
    ;;
esac

# jsonpath is used because it extracts the node name reliably.
NODE="$(kubectl get pod -n "$NS" "$POD" -o jsonpath='{.spec.nodeName}')"
if [ -z "$NODE" ]; then
  echo "Could not resolve node for pod: $POD" >&2
  exit 4
fi

echo "== selected pod = $POD"
echo "== selected node = $NODE"
echo "== ssh to node and show logs"

# The SSH below enters the selected node, goes to the log directory,
# lists recent log files, and tails the newest matching .log file.
ssh "$NODE" "
  cd '$LOG_DIR' &&
  pwd &&
  echo '== latest log files ==' &&
  ls -ltr $LOG_GLOB 2>/dev/null | tail -20 &&
  latest=\$(ls -t $LOG_GLOB 2>/dev/null | head -1);
  if [ -z \"\$latest\" ]; then
    echo 'No .log file found.' >&2;
    exit 5;
  fi;
  echo;
  echo '== tail ==';
  tail -n $TAIL_LINES \"\$latest\"
"
