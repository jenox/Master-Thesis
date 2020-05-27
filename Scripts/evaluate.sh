#!/bin/bash

export SWIFT_DETERMINISTIC_HASHING="1"

SCRIPT_PATH=$(dirname "$0")
PACKAGE_PATH="$SCRIPT_PATH/../Implementation/Modules/"
INPUT_DIRECTORY="$SCRIPT_PATH/../Evaluation/graphs/"
OUTPUT_DIRECTORY="$SCRIPT_PATH/../Evaluation/metrics/"

function evaluate {        
    swift run --package-path="$PACKAGE_PATH" --configuration=release Evaluation evaluate --number-of-vertices="$1" --nesting-ratio="$2" --nesting-bias="$3" --input-directory="$INPUT_DIRECTORY" --output-directory="$OUTPUT_DIRECTORY"
}

time (
evaluate 10 0 0 &&
evaluate 10 0.25 0 &&
evaluate 10 0.25 0.5 &&
evaluate 10 0.25 0.99 &&
evaluate 10 0.5 0 &&
evaluate 10 0.5 0.5 &&
evaluate 10 0.5 0.99 &&
evaluate 15 0 0 &&
evaluate 15 0.25 0 &&
evaluate 15 0.25 0.5 &&
evaluate 15 0.25 0.99 &&
evaluate 15 0.5 0 &&
evaluate 15 0.5 0.5 &&
evaluate 15 0.5 0.99 &&
# evaluate 20 0 0 &&
# evaluate 20 0.25 0 &&
# evaluate 20 0.25 0.5 &&
# evaluate 20 0.25 0.99 &&
# evaluate 20 0.5 0 &&
# evaluate 20 0.5 0.5 &&
# evaluate 20 0.5 0.99 &&
evaluate 25 0 0 &&
evaluate 25 0.25 0 &&
evaluate 25 0.25 0.5 &&
evaluate 25 0.25 0.99 &&
evaluate 25 0.5 0 &&
evaluate 25 0.5 0.5 &&
evaluate 25 0.5 0.99 &&
evaluate 30 0 0 &&
evaluate 30 0.25 0 &&
evaluate 30 0.25 0.5 &&
evaluate 30 0.25 0.99 &&
evaluate 30 0.5 0 &&
evaluate 30 0.5 0.5 &&
evaluate 30 0.5 0.99 &&
: # no-op
)
