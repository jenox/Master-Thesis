#!/bin/bash

export SWIFT_DETERMINISTIC_HASHING="1"

SCRIPT_PATH=$(dirname "$0")
PACKAGE_PATH="$SCRIPT_PATH/../Implementation/Modules/"
INPUT_FILE="$SCRIPT_PATH/../Evaluation/uuids.txt"
OUTPUT_DIRECTORY="$SCRIPT_PATH/../Evaluation/graphs/"

function pipeline {
    swift run --package-path="$PACKAGE_PATH" --configuration=release Evaluation pipeline --number-of-vertices="$1" --nesting-ratio="$2" --nesting-bias="$3" --number-of-optimization-steps-per-vertex=10 --number-of-dynamic-operations=20 --uuid-file="$INPUT_FILE" --output-directory="$OUTPUT_DIRECTORY"
}

time pipeline 10 0 0 &&
time pipeline 10 0.25 0 &&
time pipeline 10 0.25 0.5 &&
time pipeline 10 0.25 0.99 &&
time pipeline 10 0.5 0 &&
time pipeline 10 0.5 0.5 &&
time pipeline 10 0.5 0.99 &&
time pipeline 15 0 0 &&
time pipeline 15 0.25 0 &&
time pipeline 15 0.25 0.5 &&
time pipeline 15 0.25 0.99 &&
time pipeline 15 0.5 0 &&
time pipeline 15 0.5 0.5 &&
time pipeline 15 0.5 0.99 &&
time pipeline 20 0 0 &&
time pipeline 20 0.25 0 &&
time pipeline 20 0.25 0.5 &&
time pipeline 20 0.25 0.99 &&
time pipeline 20 0.5 0 &&
time pipeline 20 0.5 0.5 &&
time pipeline 20 0.5 0.99 &&
time pipeline 25 0 0 &&
time pipeline 25 0.25 0 &&
time pipeline 25 0.25 0.5 &&
time pipeline 25 0.25 0.99 &&
time pipeline 25 0.5 0 &&
time pipeline 25 0.5 0.5 &&
time pipeline 25 0.5 0.99 &&
time pipeline 30 0 0 &&
time pipeline 30 0.25 0 &&
time pipeline 30 0.25 0.5 &&
time pipeline 30 0.25 0.99 &&
time pipeline 30 0.5 0 &&
time pipeline 30 0.5 0.5 &&
time pipeline 30 0.5 0.99 &&
: # no-op
