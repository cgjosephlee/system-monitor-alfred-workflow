#!/bin/bash
# AirPods Battery CLI, Version 2.3
# Contributors: duk242, ankushg, spetykowski, danozdotnet
# Released under the MIT License.

# The MIT License (MIT)

# Copyright (c) 2017 Dustin Kerr, and Daniel Jones

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# https://github.com/duk242/AirPodsBatteryCLI

BLUETOOTH_DEFAULTS=$(defaults read /Library/Preferences/com.apple.Bluetooth); SYSTEM_PROFILER=$(system_profiler SPBluetoothDataType)
MAC_ADDR=$(grep -b2 "Minor Type: Headphones"<<<"${SYSTEM_PROFILER}"|awk '/Address/{print $3}')
if [[ "$MAC_ADDR" ]]; then
    CONNECTED=$(grep -ia6 "${MAC_ADDR}"<<<"${SYSTEM_PROFILER}"|awk '/Connected: Yes/{print 1}')
fi
BLUETOOTH_DATA=$(grep -ia6 '"'"${MAC_ADDR}"'"'<<<"${BLUETOOTH_DEFAULTS}")
BATTERY_LEVELS=("BatteryPercentCombined" "HeadsetBattery" "BatteryPercentSingle" "BatteryPercentCase" "BatteryPercentLeft" "BatteryPercentRight")

if [[ "${CONNECTED}" ]]; then
  for I in "${BATTERY_LEVELS[@]}"; do
    declare -x "${I}"="$(awk -v pat="${I}" '$0~pat{gsub (";",""); print $3 }'<<<"${BLUETOOTH_DATA}")"
    [[ ! -z "${!I}" ]] && OUTPUT="${OUTPUT} $(awk '/BatteryPercent/{print substr($0,15,1)": "}'<<<"${I}")${!I}%"
  done
  printf "%s\\n" "${OUTPUT}"
else
  printf "%s Not Connected\\n" "${OUTPUT}"
fi
