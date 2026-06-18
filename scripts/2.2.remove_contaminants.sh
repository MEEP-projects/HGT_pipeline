#!/bin/bash

# Check if three arguments (file1, file2, output_file) are provided
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <file1> <file2> <output_file>"
  exit 1
fi

# Get the input files and output file from command-line arguments
file1="$1"
file2="$2"
output_file="$3"

# Create or empty the output file
> "$output_file"

# Loop through each line in file1
while IFS= read -r line; do
  # Extract the value from the first column of the current line
  first_column=$(echo "$line" | awk '{print $1}')

  # Check if the value exists in file2
  if grep -q -w "$first_column" "$file2"; then
    # If it doesn't exist in file2, write the line to the output file
    echo "$line" >> "$output_file"
  fi
done < "$file1"

echo "Lines with first column values PRESENT in $file2 have been saved to $output_file."
