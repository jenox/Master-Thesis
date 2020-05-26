#!/bin/bash

SCRIPT_PATH=$(dirname "$0")
export SWIFT_DETERMINISTIC_HASHING="1"
"$SCRIPT_PATH/Evaluation" generate --number-of-identifiers=200 --output-file="$SCRIPT_PATH/uuids.txt"
