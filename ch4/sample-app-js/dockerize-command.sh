
#!/usr/bin/env bash
set -e

BUILDER_NAME="multiarch-builder"

if docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
    echo "Buildx builder '$BUILDER_NAME' already exists."
else
    echo "Creating Buildx builder '$BUILDER_NAME'..."

    docker buildx create \
        --name "$BUILDER_NAME" \
        --driver docker-container \
        --use
fi

name=$(npm pkg get name | tr -d '"')
version=$(npm pkg get version | tr -d '"')

docker buildx build \
    --platform=linux/amd64 \
    --load \
    -t "$name:$version" . \