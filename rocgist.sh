#!/bin/bash
# Usage: ./rocgist.sh path/to/execute.roc [path/to/additional/file...]

ROC_FILE="$1"
shift  # Remove first arg, leaving additional files in $@
STDOUT="STDOUT.txt"
STDERR="STDERR.txt"
DATE="$(date)"

# Prepend timestamp to output files
echo "# Run at $DATE" > "$STDOUT"
echo "# Run at $DATE" > "$STDERR"

# Run script and append output
roc "$ROC_FILE" >> "$STDOUT" 2>> "$STDERR"

# Upload to gist with additional files if provided
gh gist create "$ROC_FILE" "$STDOUT" "$STDERR" $@ -d "roc $ROC_FILE on $DATE"

echo Gist created with $ROC_FILE $STDOUT $STDERR $@
