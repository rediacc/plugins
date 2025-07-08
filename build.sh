#!/bin/bash

tag=$(date +%Y-%m-%d)

# Get the directory where the script is located
script_dir=$(dirname "$0")

# Load environment variables if .env exists in parent directories
if [ -f "$script_dir/../../.env" ]; then
    source "$script_dir/../../.env"
fi

# Default base image if not set
BASE_IMAGE=${SYSTEM_BASE_IMAGE:-"ubuntu:24.04"}

# Loop through each folder in the script directory
for folder in "$script_dir"/*; do
    if [ -d "$folder" ]; then  # Check if it's a directory
        image="rediacc/plugin-$(basename $folder)"
        echo "Building Docker image for folder: $folder with base image: $BASE_IMAGE" && \
        docker build --build-arg BASE_IMAGE="$BASE_IMAGE" -t "$image:$tag" "$folder"     && \
        docker tag "$image:$tag" "$image:latest"    && \
        docker push $image:$tag                     && \
        docker push $image:latest
    fi
done
