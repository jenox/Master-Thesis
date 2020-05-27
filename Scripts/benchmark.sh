#!/bin/bash

export SWIFT_DETERMINISTIC_HASHING="1"

SCRIPT_PATH=$(dirname "$0")
PACKAGE_PATH="$SCRIPT_PATH/../Implementation/Modules/"

time swift run --package-path="$PACKAGE_PATH" --configuration=release Evaluation benchmark
