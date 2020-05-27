#!/bin/bash

export SWIFT_DETERMINISTIC_HASHING="1"

SCRIPT_PATH=$(dirname "$0")
PACKAGE_PATH="$SCRIPT_PATH/../Implementation/Modules/"
OUTPUT_FILE="$SCRIPT_PATH/../Evaluation/uuids.txt"

swift run --package-path="$PACKAGE_PATH" --configuration=release Evaluation generate --number-of-identifiers=100 --output-file="$OUTPUT_FILE"
