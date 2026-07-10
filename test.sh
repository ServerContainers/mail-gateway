#!/bin/bash
#
# Automated test suite for the mail-gateway container.
#
# Builds the image, starts a container, waits for the (slow) clamav/amavis
# services to come up and then asserts that all expected processes and runit
# services are healthy. Exits non-zero on the first failed assertion.
#
set -u

IMAGE="mailgw-trixie:test"
NAME="mailgw-trixie-run"
FAILED=0

log()  { echo -e "\n>> $*"; }
pass() { echo "   PASS: $*"; }
fail() { echo "   FAIL: $*"; FAILED=1; }

cleanup() {
  log "cleanup: removing container $NAME"
  docker rm -f "$NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

log "building image $IMAGE (this is slow: freshclam + razor/pyzor register over network)"
if ! docker build -t "$IMAGE" .; then
  echo "BUILD FAILED"
  exit 1
fi

log "starting container $NAME"
docker rm -f "$NAME" >/dev/null 2>&1 || true
if ! docker run -d --name "$NAME" \
      -e MAIL_FQDN=gw.test.tld \
      -e RELAYHOST=relay.test.tld:25 \
      "$IMAGE" >/dev/null; then
  echo "docker run FAILED"
  exit 1
fi

# ---------------------------------------------------------------------------
# wait (retry loop) for the slow services (clamd + amavisd) to come up
# ---------------------------------------------------------------------------
log "waiting for services to come up (up to ~120s)"
ready=0
for i in $(seq 1 40); do
  if ! docker ps --format '{{.Names}}' | grep -q "^${NAME}$"; then
    echo "   container exited early!"
    docker logs "$NAME" 2>&1 | tail -40
    exit 1
  fi
  if docker exec "$NAME" sh -c 'ps ax | grep -q "[a]mavisd" && ps ax | grep -q "[c]lamd" && ps ax | grep -q "[m]aster"'; then
    ready=1
    echo "   services up after ~$((i*3))s"
    break
  fi
  sleep 3
done
if [ "$ready" -ne 1 ]; then
  fail "services did not come up within timeout"
  docker logs "$NAME" 2>&1 | tail -60
fi

# ---------------------------------------------------------------------------
# assertions
# ---------------------------------------------------------------------------
log "running assertions"

# 1. container is running
if docker ps --format '{{.Names}}' | grep -q "^${NAME}$"; then
  pass "container is running"
else
  fail "container is not running"
fi

# 2. postfix/master present
if docker exec "$NAME" sh -c 'ps ax | grep -q "[m]aster"'; then
  pass "postfix master process present"
else
  fail "postfix master process NOT present"
fi

# 3. amavisd present
if docker exec "$NAME" sh -c 'ps ax | grep -q "[a]mavisd"'; then
  pass "amavisd process present"
else
  fail "amavisd process NOT present"
fi

# 4. clamd present
if docker exec "$NAME" sh -c 'ps ax | grep -q "[c]lamd"'; then
  pass "clamd process present"
else
  fail "clamd process NOT present"
fi

# 5. postfix check exits 0
if docker exec "$NAME" postfix check; then
  pass "postfix check clean (exit 0)"
else
  fail "postfix check returned non-zero"
fi

# 6. SMTP on port 25 returns a 220 banner
# NOTE: /dev/tcp is a bash feature - the container's /bin/sh is dash, so use bash.
BANNER=""
for i in $(seq 1 15); do
  BANNER=$(docker exec "$NAME" bash -c 'exec 3<>/dev/tcp/127.0.0.1/25; head -1 <&3' 2>/dev/null)
  echo "$BANNER" | grep -q '^220' && break
  sleep 2
done
if echo "$BANNER" | grep -q '^220'; then
  pass "SMTP port 25 banner: $BANNER"
else
  fail "SMTP port 25 did not return 220 banner (got: '$BANNER')"
fi

# 7. all runit services in run: state
log "runit service status"
SV_OUT=$(docker exec "$NAME" sh -c 'sv status /etc/service/*' 2>&1)
echo "$SV_OUT"
if [ -z "$SV_OUT" ]; then
  fail "no runit services found"
elif echo "$SV_OUT" | grep -qvE '^run:'; then
  fail "one or more runit services are NOT in run: state"
else
  pass "all runit services in run: state"
fi

# ---------------------------------------------------------------------------
# summary
# ---------------------------------------------------------------------------
echo
if [ "$FAILED" -eq 0 ]; then
  echo "=============================="
  echo " ALL TESTS PASSED"
  echo "=============================="
  exit 0
else
  echo "=============================="
  echo " TESTS FAILED"
  echo "=============================="
  exit 1
fi
