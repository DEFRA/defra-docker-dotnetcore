ARG PARENT_VERSION=2.1.6-dotnet10.0

# Development stage, used the build the app and provide testing tools
FROM defradigital/dotnetcore-development:$PARENT_VERSION AS development

ENV TZ="Europe/London"

ARG PARENT_VERSION

# Label the development image with the parent image it extends
LABEL uk.gov.defra.parent-image=defradigital/dotnetcore-development:${PARENT_VERSION}

# Create directories for app and test files to be copied into
RUN mkdir -p /home/dotnet/exampleService/ /home/dotnet/exampleService.Tests/

# Install test dependencies
COPY --chown=dotnet:dotnet ./exampleService.Tests/*.csproj ./exampleService.Tests/
RUN dotnet restore ./exampleService.Tests/exampleService.Tests.csproj

# Install app dependencies
COPY --chown=dotnet:dotnet ./exampleService/*.csproj ./exampleService/
RUN dotnet restore ./exampleService/exampleService.csproj

# Copy in test and app code
COPY --chown=dotnet:dotnet ./exampleService.Tests/ ./exampleService.Tests/
COPY --chown=dotnet:dotnet ./exampleService/ ./exampleService/

# Build the app
RUN dotnet publish ./exampleService/ -c Release -o /home/dotnet/out

# Expose the app on a defined port, configurable via a build argument
ARG PORT=3000
ENV PORT=${PORT}
EXPOSE ${PORT}

# Exec form needs a script to interpolate ${PORT}; the script itself execs dotnet so it still
#   receives signals directly rather than a shell.
COPY --chown=dotnet:dotnet dev-entrypoint.sh ./
RUN chmod +x ./dev-entrypoint.sh
CMD ["./dev-entrypoint.sh"]

# Production stage
FROM defradigital/dotnetcore:$PARENT_VERSION AS production

ARG PARENT_VERSION
ARG PARENT_REGISTRY

# Label the production image with the parent image it extends
LABEL uk.gov.defra.parent-image=defradigital/dotnetcore-development:${PARENT_VERSION}

# Expose the app on a defined port, configurable via a build argument
ARG PORT=3000
ENV ASPNETCORE_URLS=http://*:${PORT}
EXPOSE ${PORT}

# Switch to root temporarily to lock down file permissions.
USER root

# Copy the compiled app from the development build stage, assigning root ownership to
#   prevent modification by other users.
COPY --from=development --chown=root:root /home/dotnet/out/ ./

# Remove write permissions, then drop back to the unprivileged user.
RUN chmod -R a-w /home/dotnet
USER dotnet

# Set the default command for production to run the compiled app.
CMD ["dotnet", "exampleService.dll"]
