#!/bin/bash

SCRIPT_PATH=$(dirname "$0")
export SWIFT_DETERMINISTIC_HASHING="1"

function evaluate {
    echo "$4"
    mkdir -p "$SCRIPT_PATH/../Evaluation/graphs/$4/"
    NUMBER_OF_STEPS_PER_VERTEX=10
    NUMBER_OF_OPERATIONS=20

    swift run --package-path="$SCRIPT_PATH/../Implementation/Modules/" --configuration=release Evaluation pipeline --number-of-vertices="$1" --nesting-ratio="$2" --nesting-bias="$3" --number-of-optimization-steps-per-vertex="$NUMBER_OF_STEPS_PER_VERTEX" --number-of-dynamic-operations="$NUMBER_OF_OPERATIONS" --uuid-file="$SCRIPT_PATH/../Evaluation/uuids.txt" --output-directory="$SCRIPT_PATH/../Evaluation/graphs/$4/"
}

evaluate 10 0 0 "10-0.0-0.0"
evaluate 10 0.25 0 "10-0.25-0.0"
evaluate 10 0.25 0.5 "10-0.25-0.5"
evaluate 10 0.25 0.99 "10-0.25-1.0"
evaluate 10 0.5 0 "10-0.5-0.0"
evaluate 10 0.5 0.5 "10-0.5-0.5"
evaluate 10 0.5 0.99 "10-0.5-1.0"
evaluate 15 0 0 "15-0.0-0.0"
evaluate 15 0.25 0 "15-0.25-0.0"
evaluate 15 0.25 0.5 "15-0.25-0.5"
evaluate 15 0.25 0.99 "15-0.25-1.0"
evaluate 15 0.5 0 "15-0.5-0.0"
evaluate 15 0.5 0.5 "15-0.5-0.5"
evaluate 15 0.5 0.99 "15-0.5-1.0"
evaluate 20 0 0 "20-0.0-0.0"
evaluate 20 0.25 0 "20-0.25-0.0"
evaluate 20 0.25 0.5 "20-0.25-0.5"
evaluate 20 0.25 0.99 "20-0.25-1.0"
evaluate 20 0.5 0 "20-0.5-0.0"
evaluate 20 0.5 0.5 "20-0.5-0.5"
evaluate 20 0.5 0.99 "20-0.5-1.0"
evaluate 25 0 0 "25-0.0-0.0"
evaluate 25 0.25 0 "25-0.25-0.0"
evaluate 25 0.25 0.5 "25-0.25-0.5"
evaluate 25 0.25 0.99 "25-0.25-1.0"
evaluate 25 0.5 0 "25-0.5-0.0"
evaluate 25 0.5 0.5 "25-0.5-0.5"
evaluate 25 0.5 0.99 "25-0.5-1.0"
evaluate 30 0 0 "30-0.0-0.0"
evaluate 30 0.25 0 "30-0.25-0.0"
evaluate 30 0.25 0.5 "30-0.25-0.5"
evaluate 30 0.25 0.99 "30-0.25-1.0"
evaluate 30 0.5 0 "30-0.5-0.0"
evaluate 30 0.5 0.5 "30-0.5-0.5"
evaluate 30 0.5 0.99 "30-0.5-1.0"
