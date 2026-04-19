#!/bin/bash

# Download SPEC CPU 2017 traces from the DPC-3 ChampSim trace repository.
#
# Traces are kept in their native .xz format since the simulator's
# ChampSimTrace reader handles both .gz and .xz natively
# (see utils/fileutils.cc lines 214-217).
#
# SimPoint selection: each trace below is the HIGHEST-WEIGHTED SimPoint
# for its benchmark, determined from the official weights file at:
#   https://dpc3.compas.cs.stonybrook.edu/champsim-traces/speccpu/weights-and-simpoints-speccpu.tar.gz
#
# Usage:
#   bash download_spec.sh

set -e

echo "============================================"
echo " Downloading SPEC CPU 2017 Traces"
echo "============================================"

DIR="traces/spec2017"
mkdir -p "$DIR"

BASE_URL="https://dpc3.compas.cs.stonybrook.edu/champsim-traces/speccpu"

# 4 SPEC CPU 2017 traces — highest-weighted SimPoint for each benchmark
#
# Benchmark           SimPoint  Weight   Description
# 605.mcf_s           665B      0.4405   Memory-intensive combinatorial optimization
# 602.gcc_s           734B      0.6412   Compiler workload
# 600.perlbench_s     210B      0.4810   Perl interpreter
# 623.xalancbmk_s     700B      0.4131   XML processing

TRACE_NAMES=("mcf" "gcc" "perlbench" "xalancbmk")
TRACE_FILES=(
    "605.mcf_s-665B.champsimtrace.xz"
    "602.gcc_s-734B.champsimtrace.xz"
    "600.perlbench_s-210B.champsimtrace.xz"
    "623.xalancbmk_s-700B.champsimtrace.xz"
)

for i in "${!TRACE_NAMES[@]}"; do
    name="${TRACE_NAMES[$i]}"
    file="${TRACE_FILES[$i]}"
    dest="$DIR/${name}.champsimtrace.xz"

    if [ -f "$dest" ]; then
        echo "[SKIP] $dest already exists"
        continue
    fi

    echo ""
    echo "--- Downloading $name ---"
    echo "  File: $file"
    echo "  URL:  $BASE_URL/$file"

    if ! wget -q --show-progress -O "$dest" "$BASE_URL/$file"; then
        echo "[ERROR] Failed to download $name"
        rm -f "$dest"
        continue
    fi

    echo "  [OK] $dest ready"
done

echo ""
echo "============================================"
echo " Download complete!"
echo "============================================"
echo ""
echo "Traces available in $DIR/:"
ls -lh "$DIR"/*.xz 2>/dev/null || echo "  (none found)"