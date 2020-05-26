#!/bin/bash

SCRIPT_PATH=$(dirname "$0")
export SWIFT_DETERMINISTIC_HASHING="1"

swift run --package-path="$SCRIPT_PATH/../Implementation/Modules/" --configuration=release Evaluation benchmark
