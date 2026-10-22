#!/usr/bin/env bash
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export PDK_ROOT="${PDK_ROOT:-$HOME/eda/pdks}"
export ASIC_CONFIG="$here/config.json"
export ASIC_RUNS="${ASIC_RUNS:-$HOME/eda/asic-runs/pipeline_cache}"
export ASIC_JOBS="${ASIC_JOBS:-8}"
export ASIC_TAG="${ASIC_TAG:-$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$ASIC_RUNS"
# Resolve source-relative paths before moving the run configuration outside Git.
export ASIC_RESOLVED_CONFIG="$ASIC_RUNS/config-$ASIC_TAG.json"
python3 - <<'PY'
import json, os
from pathlib import Path
source = Path(os.environ["ASIC_CONFIG"])
config = json.loads(source.read_text())
def resolve(value):
    if isinstance(value, str) and value.startswith("dir::"):
        return str((source.parent / value[5:]).resolve())
    if isinstance(value, list):
        return [resolve(item) for item in value]
    return value
Path(os.environ["ASIC_RESOLVED_CONFIG"]).write_text(
    json.dumps({key: resolve(value) for key, value in config.items()}, indent=2) + "\n"
)
PY
case "${1:-synth}" in
    synth) export ASIC_STOP=OpenROAD.STAPrePNR ;;
    full) export ASIC_STOP= ;;
    *) echo 'Usage: bash pipeline_cache/asic/run.sh [synth|full]' >&2; exit 2 ;;
esac
appimage="${LIBRELANE_APPIMAGE:-$HOME/eda/appimages/librelane-3.0.16-x86_64.AppImage}"
if [[ ! -x "$appimage" ]]; then
    echo "LibreLane AppImage not executable: $appimage" >&2
    exit 1
fi
args=(librelane --pdk sky130A --scl sky130_fd_sc_hd --jobs "$ASIC_JOBS"
    --design-dir "$ASIC_RUNS" --run-tag "$ASIC_TAG")
if [[ -n "$ASIC_STOP" ]]; then args+=(--to "$ASIC_STOP"); fi
"$appimage" "${args[@]}" "$ASIC_RESOLVED_CONFIG"
