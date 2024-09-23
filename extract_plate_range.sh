#!/bin/bash

# check and print message if arguments are not correct
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <base_directory> <plate_range>"
    echo "Example: $0 /path/to/data plate0xxx-plate0xxx"
    exit 1
fi

base_dir="$1"
plate_range="$2"

# Extract start and end plate numbers from the range
start_plate=$(echo $plate_range | cut -d'-' -f1 | sed 's/[^0-9]*//g')
end_plate=$(echo $plate_range | cut -d'-' -f2 | sed 's/[^0-9]*//g')

# Generate output file name based on the range and log file to show all files processed
output_file="plate_${start_plate}-${end_plate}_amplicon_depth_summary.tsv"
log_file="plate_${start_plate}-${end_plate}_processing.log"


# Generate the list of amplicons
amplicons=$(awk '!/^reference_name/ {print $4}' $(seq -f "$base_dir/Plate%04g*/qc_sequencing/*amplicon_depth.bed" $start_plate $end_plate) | sort -t_ -k2n | uniq)
#header="PlateName\tSampleName\t$(printf '%s\t' $amplicons)" #printf is causing issue with \t
header="PlateName\tSampleName"
for amplicon in $amplicons; do
    header="$header\t$amplicon"
done
echo -e "$header" > "$output_file"


# Process each BED file within the range of plate names
for plate_num in $(seq $start_plate $end_plate); do
    for bed_file in "$base_dir"/Plate$(printf "%04d" $plate_num)*/qc_sequencing/*amplicon_depth.bed; do
        if [ -f "$bed_file" ]; then
            plate_name=$(basename "$(dirname "$(dirname "$bed_file")")")
            if [[ $plate_name == *T* ]]; then
                continue
            fi
            sample_name=$(basename "$bed_file" .amplicon_depth.bed)
            if [[ $sample_name == Neg* || $sample_name == NTC* || $sample_name == Pos* ]]; then
                continue
            fi
            depth_values=$(awk '!/^reference_name/ {printf "%s\t", $7}' "$bed_file" | sed 's/\t$//')
            row="$plate_name\t$sample_name\t$depth_values"
            echo -e "$row" >> "$output_file"
        fi
    done
done