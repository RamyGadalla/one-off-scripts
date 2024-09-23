#!/bin/bash

# check and print message if arguments are not correct
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <base_directory> <plate_range> <YYYY>"
    echo "Example: $0 /path/to/data plate0xxx-plate0xxx 2022"
    exit 1
fi

base_dir="$1"
plate_range="$2"
year="$3"

# Extract start and end plate numbers from the range
start_plate=$(echo $plate_range | cut -d'-' -f1 | sed 's/[^0-9]*//g')
end_plate=$(echo $plate_range | cut -d'-' -f2 | sed 's/[^0-9]*//g')

# Generate output file name based on the range and log file to show all files processed
output_file="plate_${start_plate}-${end_plate}_${year}_amplicon_depth_summary.tsv"
log_file="plate_${start_plate}-${end_plate}_${year}_processing.log"


# Generate the list of amplicons. If "qc_sequceing" exit, extract amplicon.
amplicons=$(for dir in $(seq -f "$base_dir/Plate%04g_${year}*" $start_plate $end_plate); do
    if [ -d "$dir/qc_sequencing" ]; then
        find "$dir/qc_sequencing" -name "*.amplicon_depth.bed"
    fi
done | xargs awk '!/^reference_name/ {print $4}' | sort -t_ -k2n | uniq)


#header="PlateName\tSampleName\t$(printf '%s\t' $amplicons)" #printf is causing issue with \t
header="PlateName\tSampleName"
for amplicon in $amplicons; do
    header="$header\t$amplicon"
done
echo -e "$header" > "$output_file"


echo "Amplicons extracted: \n $amplicons ..."


# Process each BED file within the range of plate names
for plate_num in $(seq -f "%04g" $start_plate $end_plate); do
    #for dir in $(find "$base_dir" -type d -name "Plate${plate_num}_${year}*"); do # find is throwing error. use ls instead (next line)
    for dir in $(ls -d "$base_dir"/Plate${plate_num}_${year}* 2>/dev/null); do
        if [ -d "$dir/qc_sequencing" ]; then
            for bed_file in "$dir"/qc_sequencing/*.amplicon_depth.bed; do
                if [ -f "$bed_file" ]; then
                    plate_name=$(basename "$(dirname "$(dirname "$bed_file")")")
                    if [[ $plate_name == *T* ]]; then
                        continue
                    fi
                    sample_name=$(basename "$bed_file" .amplicon_depth.bed)
                    if [[ $sample_name == Neg* || $sample_name == NTC* || $sample_name == Pos* ]]; then
                        continue
                    fi
                    # Log the processed file
                    echo "Processing file: $bed_file" >> "$log_file"
                    # Extract depth values and write the output
                    depth_values=$(awk '!/^reference_name/ {printf "%s\t", $7}' "$bed_file" | sed 's/\t$//')
                    row="$plate_name\t$sample_name\t$depth_values"
                    echo -e "$row" >> "$output_file"
                fi
            done
        fi
    done
done