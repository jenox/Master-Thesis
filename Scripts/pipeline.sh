#!/bin/bash

SCRIPT_PATH=$(dirname "$0")
export SWIFT_DETERMINISTIC_HASHING="1"

function evaluate {
    echo "$SCRIPT_PATH/$4/"
    mkdir -p "$SCRIPT_PATH/$4/"
    NUMBER_OF_STEPS=100
    NUMBER_OF_OPERATIONS=20
    "$SCRIPT_PATH/Evaluation" pipeline --number-of-vertices="$1" --nesting-ratio="$2" --nesting-bias="$3" --number-of-optimization-steps="$NUMBER_OF_STEPS" --number-of-dynamic-operations="$NUMBER_OF_OPERATIONS" --uuid-file="$SCRIPT_PATH/uuids.txt" --output-directory="$SCRIPT_PATH/$4/"
}

# evaluate 10 0 0 "10-0-0"
# evaluate 10 0.5 0 "10-0.5-0"
# evaluate 10 0.5 0.5 "10-0.5-0.5"
# evaluate 10 0.5 0.99 "10-0.5-1"
evaluate 15 0 0 "15-0-0"
evaluate 15 0.5 0 "15-0.5-0"
evaluate 15 0.5 0.5 "15-0.5-0.5"
evaluate 15 0.5 0.99 "15-0.5-1"
