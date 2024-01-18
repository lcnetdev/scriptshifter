#!/bin/bash

# CAMeL romanization language model setup
# Adapted from https://github.com/fadhleryani/Arabic_ALA-LC_Romanization#data-1

set -e

BASEDIR=$( dirname -- "$( readlink -f -- "$0"; )")

cd "${BASEDIR}/../../../ext/arabic_rom"

# Download data
if [ ! -d "./data/raw_records" ]; then
    echo "Downloading data."
    make download_data
fi

# Collect Arabic records
echo "Collecting records."
python src/data/collect_arabic_records.py data/raw_records/umich
python src/data/collect_arabic_records.py data/raw_records/loc
python src/data/collect_arabic_records.py data/raw_records/aco/work --sub_directory_filter marcxml_out

# Extract parallel lines
echo "Extracting lines."
make extract_lines

# Clean, preprocess, and split
echo "Preprocessing data set."
make data_set

# Train MLE model
echo "Bulding MLE simple rules."
python src/loc_transcribe.py predict simple dev
python3 src/loc_transcribe.py train mle --size {1,0.5,0.25,0.125,0.0625,0.03125,0.015625}
python3 src/loc_transcribe.py predict mle dev --mle_model models/mle/size1.0.tsv --backoff predictions_out/simple/dev/simple.out
#make predict_mle  # NOTE this should replace the 2 lines above but there is no Makefile target.

# Seq2Seq
echo "Preparing Seq2seq."
make prep_seq2seq
echo "Training models."
python3 src/loc_transcribe.py train seq2seq --train --size {1.0,0.5,0.25,0.125,0.0625,0.03125,0.015625}
