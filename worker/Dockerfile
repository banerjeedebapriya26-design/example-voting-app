# Use the SDK image for building
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG TARGETARCH
WORKDIR /source

# Copy all files at once to maintain a consistent build context
COPY . .

# Combine restore and publish into a single command. 
# We remove --no-restore so the SDK can map dependencies to the TARGETARCH RID.
RUN dotnet publish -c release -o /app -a $TARGETARCH --self-contained false

# Use the lightweight runtime image for the final container
FROM mcr.microsoft.com/dotnet/runtime:8.0
WORKDIR /app

# Copy only the compiled binaries from the build stage
COPY --from=build /app .

# Start the worker
ENTRYPOINT ["dotnet", "Worker.dll"]
