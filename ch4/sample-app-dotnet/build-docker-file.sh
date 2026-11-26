# ==========================================
# Docker Buildx
# ==========================================

if ! docker buildx version >/dev/null 2>&1; then
    echo "Error: Docker Buildx is not installed."
    exit 1
fi

BUILDER_NAME="dotnet-builder"

# Check whether builder exists
if ! docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
    echo "Creating Buildx builder: $BUILDER_NAME"

    docker buildx create \
        --name "$BUILDER_NAME" \
        --driver docker-container
fi

# Select builder
docker buildx use "$BUILDER_NAME"



docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t "test-app:v1.0.0" \
    --load .