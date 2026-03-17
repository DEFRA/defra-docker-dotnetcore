# Set default values for build arguments
ARG DEFRA_VERSION=2.0.2
ARG BASE_VERSION=10.0-alpine3.23

# Extend Alpine variant of ASP.NET base image for small image size
FROM mcr.microsoft.com/dotnet/aspnet:$BASE_VERSION AS production

ARG DEFRA_VERSION
ARG BASE_VERSION

# Default the runtime image to run as production
ENV ASPNETCORE_ENVIRONMENT=production

# Update available packages
RUN apk update && apk upgrade --available

# Install Internal CA certificate for firewall and Zscaler proxy
RUN apk add --no-cache ca-certificates
COPY certificates/internal-ca.crt /usr/local/share/ca-certificates/internal-ca.crt
RUN chmod 644 /usr/local/share/ca-certificates/internal-ca.crt && update-ca-certificates

# Create a dotnet user to run as
RUN addgroup -g 1000 dotnet \
    && adduser -u 1000 -G dotnet -s /bin/sh -D dotnet

# Default to the dotnet user and run from their home folder
USER dotnet
WORKDIR /home/dotnet

# Label images to aid searching
LABEL uk.gov.defra.dotnetcore.dotnet-version=$BASE_VERSION \
      uk.gov.defra.dotnetcore.version=$DEFRA_VERSION \
      uk.gov.defra.dotnetcore.repository=defradigital/dotnetcore

# Extend Alpine variant of .Net Core SDK base image for small image size
FROM mcr.microsoft.com/dotnet/sdk:$BASE_VERSION AS development

ARG DEFRA_VERSION
ARG BASE_VERSION

# Default the SDK image to run as development
ENV ASPNETCORE_ENVIRONMENT=development

LABEL uk.gov.defra.dotnetcore.dotnet-version=$BASE_VERSION \
      uk.gov.defra.dotnetcore.version=$DEFRA_VERSION \
      uk.gov.defra.dotnetcore.repository=defradigital/dotnetcore-development

# Install additional development dependencies
RUN apk add --no-cache bash ca-certificates curl procps unzip

# Install .NET debugger to support debugging in a container
ADD https://aka.ms/getvsdbgsh /tmp/getvsdbgsh
RUN /bin/sh /tmp/getvsdbgsh -v latest -l /vsdbg && rm /tmp/getvsdbgsh

# Install Internal CA certificate for firewall and Zscaler proxy
COPY certificates/internal-ca.crt /usr/local/share/ca-certificates/internal-ca.crt
RUN chmod 644 /usr/local/share/ca-certificates/internal-ca.crt && update-ca-certificates

# Create a dotnet user to run as
RUN addgroup -g 1000 dotnet \
    && adduser -u 1000 -G dotnet -s /bin/sh -D dotnet

# Default to the dotnet user and run from their home folder
USER dotnet
WORKDIR /home/dotnet
