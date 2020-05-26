#!/bin/bash

SCRIPT_PATH=$(dirname "$0")
export SWIFT_DETERMINISTIC_HASHING="1"

"$SCRIPT_PATH/Evaluation" evaluate --sizes 10 15 20 25 30 --times 1 3 5 7 11 21 --complexities 0,0 0.25,0 0.25,0.5 0.25,1 0.5,0 0.5,0.5 0.5,1 --limited-to-number-of-identifiers 100 --uuid-file="$SCRIPT_PATH/uuids.txt" --input-directory="$SCRIPT_PATH" --output-directory="$SCRIPT_PATH/CSV/"
