![Build](https://github.com/defra/defra-docker-dotnetcore/actions/workflows/build-scan-push.yml/badge.svg)
![Nightly Scan](https://github.com/defra/defra-docker-dotnetcore/actions/workflows/nightly-scan.yml/badge.svg)
![Auto Update](https://github.com/defra/defra-docker-dotnetcore/actions/workflows/auto-update.yml/badge.svg)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=DEFRA_defra-docker-dotnetcore&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=DEFRA_defra-docker-dotnetcore)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=DEFRA_defra-docker-dotnetcore&metric=bugs)](https://sonarcloud.io/summary/new_code?id=DEFRA_defra-docker-dotnetcore)
[![Code Smells](https://sonarcloud.io/api/project_badges/measure?project=DEFRA_defra-docker-dotnetcore&metric=code_smells)](https://sonarcloud.io/summary/new_code?id=DEFRA_defra-docker-dotnetcore)
[![Duplicated Lines (%)](https://sonarcloud.io/api/project_badges/measure?project=DEFRA_defra-docker-dotnetcore&metric=duplicated_lines_density)](https://sonarcloud.io/summary/new_code?id=DEFRA_defra-docker-dotnetcore)

# Docker .NET

This repository contains .NET parent Docker image source code for Defra.

The following table lists the versions of .NET available, and the parent image they are based on:

| .NET version | SDK version | Runtime version | Parent image   |
| ------------ |-------------|---------------- | -------------- |
| 8.0          | 8.0.414     | 8.0.20          | 8.0-alpine3.21 |

Two parent images are created from this repository:

- `defra-dotnetcore`
- `defra-dotnetcore-development`

It is recommended that services use [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build) to produce production and development images, each extending the appropriate parent, from a single Dockerfile.

The development image is based on the .NET SDK, whilst the production image is based on the .NET Runtime (including ASP.NET).

### Example file

An [example](./example) is provided to show how parent images can be extended for different types of services. These should be a good starting point for building .NET services conforming to Defra standards.

[`example/Dockerfile`](example/Dockerfile) - This is an example project that consumes the parent images created by this repository.

## Supported .NET versions

Services should use the latest LTS version of .NET.

As such, the maintained parent images will align to the versions of LTS still receiving security updates.

## Internal CA certificates

The image includes the certificate for the internal [CA](https://en.wikipedia.org/wiki/Certificate_authority) so that traffic can traverse the network without encountering issues.

## Versioning

Images should be tagged according to the Dockerfile version and the version of .Net on which the image is based. For example, for Dockerfile version `1.0.0` based on .Net `8.0`, the built image would be tagged `1.0.0-dotnetcore8.0`.

## CI/CD

On commit GitHub Actions will build both `dotnetcore` and `dotnetcore-development` images for the .NET versions listed in the [image-matrix.json](image-matrix.json) file, and perform a vulnerability scan, as described below. 

In addition a commit to the master branch will push the images to the `defradigital` organisation in GitHub using the version tag specified in the [JOB.env](JOB.env) file. The version is expected to be manually updated on each release.

The .NET version marked as latest in the [image-matrix.json](image-matrix.json) will be tagged as the latest image in Docker Hub.

## Image vulnerability scanning

A GitHub Action runs a nightly scan of the images published to Docker using [Anchore Grype](https://github.com/anchore/grype/) and [Aqua Trivy](https://www.aquasec.com/products/trivy/). The latest images for each supported Node.js version are scanned.

New images are also scanned before release on any push to a branch.

This ensures Defra services that use the parent images are starting from a known secure foundation, and can limit patching to only newly added libraries.

For more details see [Image Scanning](IMAGE_SCANNING.md)

## Automated version updates

The [auto-update](/.github/workflows/auto-update.yml) workflow runs nightly to check for new versions of Node.js and their associated Alpine images. If a new version is found, the workflow will create a pull request to update to the latest version.

These updates are scoped to the Node.js versions listed in the [image-matrix.json](image-matrix.json) file.

## Building images locally

To build the images locally, run:
```
docker build --no-cache --target <target> .
```
(where <target> is either `development` or `production`).

This will build an image using the default `BASE_VERSION` as set in the [Dockerfile](Dockerfile).

## Licence

THIS INFORMATION IS LICENSED UNDER THE CONDITIONS OF THE OPEN GOVERNMENT LICENCE found at:

<http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3>

The following attribution statement MUST be cited in your products and applications when using this information.

> Contains public sector information licensed under the Open Government license v3

### About the licence

The Open Government Licence (OGL) v3.0 was developed by the The National Archives to enable information providers in the public sector to license the use and re-use of their information under a common open licence.

It is designed to encourage use and re-use of information freely and flexibly, with only a few conditions.
