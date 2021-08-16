# Set default values for build arguments
ARG DEFRA_VERSION=1.2.8
ARG BASE_VERSION=3.1-alpine3.13

# Extend Alpine variant of ASP.net base image for small image size
FROM mcr.microsoft.com/dotnet/aspnet:$BASE_VERSION AS production

ARG DEFRA_VERSION
ARG BASE_VERSION

# Default the runtime image to run as production
ENV ASPNETCORE_ENVIRONMENT=production

# Install Internal CA certificate
RUN apk update && apk add --no-cache ca-certificates && apk add --update-cache --no-cache 'apk-tools>2.12.6-r0' && rm -rf /var/cache/apk/*
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

# Install dev tools, such as remote debugger and its dependencies
# Install Internal CA certificate
# Pact dependencies are not included in Alpine image for contract testing
RUN apk update && \
    apk add --no-cache bash ca-certificates curl procps unzip wget && rm -rf /var/cache/apk/* \
    && wget -qO- https://aka.ms/getvsdbgsh | /bin/sh /dev/stdin -v latest -l /vsdbg \
    && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-2.29-r0.apk \
    && apk add glibc-2.29-r0.apk

COPY certificates/internal-ca.crt /usr/local/share/ca-certificates/internal-ca.crt
RUN chmod 644 /usr/local/share/ca-certificates/internal-ca.crt && update-ca-certificates

# Create a dotnet user to run as
RUN addgroup -g 1000 dotnet \
    && adduser -u 1000 -G dotnet -s /bin/sh -D dotnet

# Default to the dotnet user and run from their home folder
USER dotnet
WORKDIR /home/dotnet
