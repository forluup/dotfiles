#!/usr/bin/env bash
# Down/up throughput on whichever interface holds the default route, plus the
# SSID when that interface is wireless. Sampled over 1s; eww polls every 3s.

iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}')
if [ -z "$iface" ]; then
  printf '{"iface":"offline","ssid":"","down":"--","up":"--"}\n'
  exit 0
fi

counters() { awk -v i="$iface:" '$1==i {print $2, $10}' /proc/net/dev; }
human() {
  awk -v b="$1" 'BEGIN {
    split("B K M G", u); s = 1
    while (b >= 1024 && s < 4) { b /= 1024; s++ }
    printf (s == 1 ? "%d%s/s" : "%.1f%s/s"), b, u[s]
  }'
}

read -r rx1 tx1 < <(counters)
sleep 1
read -r rx2 tx2 < <(counters)

# strip characters that would break the JSON we hand back to eww
ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1=="yes" {print $2; exit}' | tr -d '"\\')

printf '{"iface":"%s","ssid":"%s","down":"%s","up":"%s"}\n' \
  "$iface" "$ssid" "$(human $((rx2 - rx1)))" "$(human $((tx2 - tx1)))"
