#!/bin/bash

# Evaluate ALL branch predictor models on ALL traces:
#   - 14 cloud/server traces (same as eval_all.sh)
#   - 4 SPEC CPU 2017 traces
#
# This is a NEW script. The existing eval_all.sh is NOT modified
# and continues to run the 14 cloud traces only.
#
# Usage:
#   ./eval_all_combined.sh

set -e


## ---- Cloud/Server Traces (14) ----
## Same list as eval_all.sh / eval_benchmarks.sh
CLOUD_TRACES=""
CLOUD_TRACES="${CLOUD_TRACES} mwnginxfpm-wiki"
CLOUD_TRACES="${CLOUD_TRACES} dacapo-kafka"
CLOUD_TRACES="${CLOUD_TRACES} dacapo-tomcat"
CLOUD_TRACES="${CLOUD_TRACES} dacapo-spring"
CLOUD_TRACES="${CLOUD_TRACES} renaissance-finagle-chirper"
CLOUD_TRACES="${CLOUD_TRACES} renaissance-finagle-http"
CLOUD_TRACES="${CLOUD_TRACES} benchbase-tpcc"
CLOUD_TRACES="${CLOUD_TRACES} benchbase-twitter"
CLOUD_TRACES="${CLOUD_TRACES} benchbase-wikipedia"
CLOUD_TRACES="${CLOUD_TRACES} nodeapp-nodeapp"
CLOUD_TRACES="${CLOUD_TRACES} charlie.1006518"
CLOUD_TRACES="${CLOUD_TRACES} delta.507252"
CLOUD_TRACES="${CLOUD_TRACES} merced.467915"
CLOUD_TRACES="${CLOUD_TRACES} whiskey.426708"


## ---- SPEC CPU 2017 Traces (4) ----
SPEC_TRACES=""
SPEC_TRACES="${SPEC_TRACES} mcf"
SPEC_TRACES="${SPEC_TRACES} gcc"
SPEC_TRACES="${SPEC_TRACES} perlbench"
SPEC_TRACES="${SPEC_TRACES} xalancbmk"


CLOUD_TRACE_DIR="./traces"
SPEC_TRACE_DIR="./traces/spec2017"


cmake --build ./build --target predictor -j $(nproc)


OUT=results/
POSTFIX="ae"


d1M=1000000

N_WARM=$(( 100 * $d1M ))
N_SIM=$(( 500 * $d1M ))


FLAGS=""
FLAGS="${FLAGS} --simulate-btb"


BRMODELS=""
BRMODELS="${BRMODELS} llbp"
BRMODELS="${BRMODELS} llbp-timing"
BRMODELS="${BRMODELS} tage64kscl"
BRMODELS="${BRMODELS} tage512kscl"


commands=()


## ---- Cloud traces ----
for model in $BRMODELS; do
    for fn in $CLOUD_TRACES; do

        TRACE=$CLOUD_TRACE_DIR/$fn.champsim.trace.gz

        if [ ! -f "$TRACE" ]; then
            echo "[WARN] Cloud trace not found: $TRACE — skipping"
            continue
        fi

        OUTDIR="${OUT}/${fn}/"
        mkdir -p $OUTDIR

        CMD="\
            ./build/predictor $TRACE \
                --model ${model} \
                ${FLAGS} \
                -w ${N_WARM} -n ${N_SIM} \
                --output \"${OUTDIR}/${model}-${POSTFIX}\" \
                > $OUTDIR/${model}-${POSTFIX}.txt 2>&1"

        commands+=("$CMD")
    done
done


## ---- SPEC traces ----
for model in $BRMODELS; do
    for fn in $SPEC_TRACES; do

        TRACE=$SPEC_TRACE_DIR/$fn.champsimtrace.xz

        if [ ! -f "$TRACE" ]; then
            echo "[WARN] SPEC trace not found: $TRACE — skipping $fn"
            echo "       Run ./download_spec.sh first."
            continue
        fi

        OUTDIR="${OUT}/spec2017-${fn}/"
        mkdir -p $OUTDIR

        CMD="\
            ./build/predictor $TRACE \
                --model ${model} \
                ${FLAGS} \
                -w ${N_WARM} -n ${N_SIM} \
                --output \"${OUTDIR}/${model}-${POSTFIX}\" \
                > $OUTDIR/${model}-${POSTFIX}.txt 2>&1"

        commands+=("$CMD")
    done
done


echo "Running ${#commands[@]} simulations (14 cloud + 4 SPEC × 4 models)"

parallel --jobs $(nproc) ::: "${commands[@]}"

wait
echo "Combined evaluation complete."