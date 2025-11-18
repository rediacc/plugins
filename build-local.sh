#!/bin/bash

# Build script for SDK plugins - local build only (no push)

# Get the directory where the script is located
script_dir=$(dirname "$0")

# Load environment variables if .env exists in parent directories
if [ -f "$script_dir/../../.env" ]; then
    source "$script_dir/../../.env"
fi

# Default base image if not set
BASE_IMAGE=${SYSTEM_BASE_IMAGE:-"ubuntu:24.04"}
DOCKER_REGISTRY=${DOCKER_REGISTRY:-""}

echo "Building SDK plugin Docker images..."
echo "Base image: $BASE_IMAGE"
echo "Registry: ${DOCKER_REGISTRY:-<none>}"

# Loop through each folder in the script directory
for folder in "$script_dir"/*; do
    if [ -d "$folder" ] && [ -f "$folder/Dockerfile" ]; then  # Check if it's a directory with Dockerfile
        plugin_name=$(basename "$folder")
        if [ -n "$DOCKER_REGISTRY" ]; then
            # Use parametric tagging: strip rediacc/ for multi-level registries
            slash_count=$(echo "$DOCKER_REGISTRY" | tr -cd '/' | wc -c)
            if [ $slash_count -ge 2 ]; then
                # Multi-level registry (e.g., ghcr.io/org/repo)
                image="${DOCKER_REGISTRY}/plugin-$plugin_name"
            else
                # Flat registry (e.g., localhost:5000)
                image="${DOCKER_REGISTRY}/rediacc/plugin-$plugin_name"
            fi
        else
            image="rediacc/plugin-$plugin_name"
        fi

        echo ""
        echo "Building $image:latest..."
        docker build --build-arg BASE_IMAGE="$BASE_IMAGE" -t "$image:latest" "$folder"

        if [ $? -eq 0 ]; then
            echo "✓ Successfully built $image:latest"
        else
            echo "✗ Failed to build $image:latest"
            exit 1
        fi
    fi
done

echo ""
echo "All plugin images built successfully!"