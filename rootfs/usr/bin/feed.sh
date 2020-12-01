#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# First socat take SBS data and sends to standard output
# pv (pipe viewer) shows stats about the transfer every 300 seconds
# Second socat reads from standard input and sends to adsbhub
# Curly braces are so we can capture entire stderr outputs
# `stdbuf -oL tr '\r' '\n'` makes pv output one stat per line (instead of updating in place)
# `stdbuf -o0 sed --unbuffered '/^$/d'` removes blank lines from output
# `stdbuf -o0 awk '{print....` prepends the `[feed] <timestamp>` to each line

set -o pipefail

echo "Feeding data from ${SBSHOST}:${SBSPORT} to ${ADSBHUBHOST}:${ADSBHUBPORT}" | \
  stdbuf -o0 awk '{print "[feed] " strftime("%Y/%m/%d %H:%M:%S", systime()) " " $0}'

{ stdbuf -oL nc -w 60 -q 10 "${SBSHOST}" "${SBSPORT}" | \
  { stdbuf -oL pv -t -r -b -f -N statistics -c --interval 300 | \
    stdbuf -oL nc -w 60 -q 10 "${ADSBHUBHOST}" "${ADSBHUBPORT}"; }; \
  } \
 2>&1 | stdbuf -oL tr '\r' '\n' | \
 stdbuf -o0 sed --unbuffered '/^$/d' | \
 stdbuf -o0 awk '{print "[feed] " strftime("%Y/%m/%d %H:%M:%S", systime()) " " $0}'

echo "Disconnected" | \
  stdbuf -o0 awk '{print "[feed] " strftime("%Y/%m/%d %H:%M:%S", systime()) " " $0}'