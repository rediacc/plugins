#!/bin/bash
set -e

# CI-agnostic Docker build and push script for Rediacc plugins
# Usage: ./ci-build.sh
# Environment variables:
#   DOCKERHUB_USERNAME - Docker Hub username (required)
#   DOCKERHUB_TOKEN - Docker Hub token (required)
#   GITHUB_REF - Git reference (optional, for tag detection)
#   BASE_IMAGE - Base image to use (default: ubuntu:24.04)
#   DRY_RUN - Set to "true" to skip pushing (default: false)

# Configuration
BASE_IMAGE=${BASE_IMAGE:-"ubuntu:24.04"}
DRY_RUN=${DRY_RUN:-"false"}
SCRIPT_DIR=$(dirname "$0")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Determine tags based on git reference
determine_tags() {
    local plugin_name=$1
    local image_base="rediacc/plugin-${plugin_name}"
    local tags=""

    # Always add latest tag
    tags="${image_base}:latest"

    # Check if we're on a version tag (v1.2.3)
    if [ -n "$GITHUB_REF" ] && [[ "$GITHUB_REF" == refs/tags/v* ]]; then
        version_tag=${GITHUB_REF#refs/tags/}
        tags="${tags},${image_base}:${version_tag}"
        log_info "Building for version tag: ${version_tag}"
    fi

    # Add date tag
    date_tag=$(date +%Y-%m-%d)
    tags="${tags},${image_base}:${date_tag}"

    echo "$tags"
}

# Docker login
docker_login() {
    if [ -z "$DOCKERHUB_USERNAME" ] || [ -z "$DOCKERHUB_TOKEN" ]; then
        log_error "DOCKERHUB_USERNAME and DOCKERHUB_TOKEN must be set"
        exit 1
    fi

    log_info "Logging into Docker Hub..."
    echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
}

# Setup buildx for multi-arch builds
setup_buildx() {
    log_info "Setting up Docker Buildx..."

    # Create builder if it doesn't exist
    if ! docker buildx inspect rediacc-builder &>/dev/null; then
        docker buildx create --name rediacc-builder --driver docker-container --bootstrap
    fi

    docker buildx use rediacc-builder
}

# Build and push a plugin
build_plugin() {
    local plugin_dir=$1
    local plugin_name=$(basename "$plugin_dir")

    if [ ! -f "$plugin_dir/Dockerfile" ]; then
        log_warn "No Dockerfile found in $plugin_dir, skipping..."
        return 0
    fi

    log_info "Building plugin: ${plugin_name}"

    local tags=$(determine_tags "$plugin_name")
    log_info "Tags: ${tags}"

    # Build arguments
    local build_args="--build-arg BASE_IMAGE=${BASE_IMAGE}"
    local platforms="linux/amd64,linux/arm64"

    # Convert comma-separated tags to multiple -t flags
    local tag_flags=""
    IFS=',' read -ra TAG_ARRAY <<< "$tags"
    for tag in "${TAG_ARRAY[@]}"; do
        tag_flags="${tag_flags} -t ${tag}"
    done

    # Build command
    local push_flag=""
    if [ "$DRY_RUN" = "true" ]; then
        log_warn "DRY_RUN mode: skipping push"
    else
        push_flag="--push"
    fi

    log_info "Building multi-arch image for platforms: ${platforms}"

    # Build (cache disabled for initial runs to avoid errors)
    if ! docker buildx build \
        --platform "${platforms}" \
        ${build_args} \
        ${tag_flags} \
        ${push_flag} \
        "$plugin_dir"; then
        log_error "Failed to build ${plugin_name}"
        return 1
    fi

    log_info "✓ Successfully built ${plugin_name}"

    # Output summary
    echo "---"
    echo "Plugin: ${plugin_name}"
    echo "Images:"
    for tag in "${TAG_ARRAY[@]}"; do
        echo "  - ${tag}"
    done
    echo "---"
}

# Main execution
main() {
    local start_time=$(date +%s)

    log_info "Starting Rediacc Plugins CI Build"
    log_info "Base Image: ${BASE_IMAGE}"

    # Login to Docker Hub
    if [ "$DRY_RUN" != "true" ]; then
        docker_login || exit 1
    fi

    # Setup buildx
    setup_buildx

    # Find and build all plugins
    local plugin_count=0
    local failed_plugins=()
    local successful_plugins=()

    for plugin_dir in "$SCRIPT_DIR"/*/; do
        if [ -d "$plugin_dir" ] && [ -f "$plugin_dir/Dockerfile" ]; then
            plugin_count=$((plugin_count + 1))
            plugin_name=$(basename "$plugin_dir")

            if build_plugin "$plugin_dir"; then
                successful_plugins+=("$plugin_name")
            else
                failed_plugins+=("$plugin_name")
            fi
        fi
    done

    if [ $plugin_count -eq 0 ]; then
        log_error "No plugins found to build"
        exit 1
    fi

    # Print summary
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo ""
    echo "================================================"
    echo "Plugin Build Summary"
    echo "================================================"

    if [ ${#successful_plugins[@]} -gt 0 ]; then
        echo -e "${GREEN}Successfully Built (${#successful_plugins[@]}):${NC}"
        for plugin in "${successful_plugins[@]}"; do
            echo "  ✓ $plugin"
        done
    fi

    if [ ${#failed_plugins[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}Failed to Build (${#failed_plugins[@]}):${NC}"
        for plugin in "${failed_plugins[@]}"; do
            echo "  ✗ $plugin"
        done
        echo ""
        echo -e "${RED}Plugin Build FAILED${NC}"
        echo "Duration: ${duration}s"
        echo ""
        log_error "Build completed with ${#failed_plugins[@]} failure(s)"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}All plugins built successfully!${NC}"
    echo "Total: $plugin_count plugin(s)"
    echo "Duration: ${duration}s"
}

# Run main
main
