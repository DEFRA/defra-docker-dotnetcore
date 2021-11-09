# Docker .NET Core

This repository contains .Net Core parent Docker image source code for Defra.

The following table lists the versions of .Net Core available, and the parent image they are based on:

| .Net Core version  | Parent image   |
| ------------------ | -------------- |
| 3.1                | 3.1-alpine3.14 |
| 6.0                | 3.1-alpine3.14 |

Two parent images are created from this repository:

- `defra-dotnetcore`
- `defra-dotnetcore-development`

It is recommended that services use [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build) to produce production and development images, each extending the appropriate parent, from a single Dockerfile.

An [example](./example) is provided to show how parent images can be extended in a Dockerfile for a service. This should be a good starting point for building .Net Core services conforming to FFC standards.

## Building images locally

To build the images locally, run:
```
docker build --no-cache --target <target> .
```
(where <target> is either `development` or `production`).

This will build an image using the default `BASE_VERSION` as set in the [Dockerfile](Dockerfile).

## Internal CA certificates

The image includes the certificate for the internal [CA](https://en.wikipedia.org/wiki/Certificate_authority) so that traffic can traverse the network without encountering issues.

## Versioning

Images should be tagged according to the Dockerfile version and the version of .Net Core on which the image is based. For example, for Dockerfile version `1.0.0` based on .Net Core `3.1.0`, the built image would be tagged `1.0.0-dotnetcore3.1.0`.

## Example file

`Dockerfile` - This is an example project that consumes the parent images created by this repository.

## CI/CD

On commit GitHub Actions will build both `dotnetcore` and `dotnetcore-development` images for the .NET Core versions listed in the [image-matrix.json](image-matrix.json) file, and perform a vulnerability scan, as described below. 

In addition a commit to the master branch will push the images to the `defradigital` organisation in GitHub using the version tag specified in the [JOB.env](JOB.env) file. The version is expected to be manually updated on each release.

The .Net Core version marked as latest in the [image-matrix.json](image-matrix.json) will be tagged as the latest image in Docker Hub.

## Image vulnerability scanning

A GitHub Action runs a nightly Anchore Engine scan of the image published to Docker, and will build and scan pre-release images on push. 

This ensures Defra services that use the parent images are starting from a known secure foundation, and can limit patching to only newly added libraries.

 For more details see [Image Scanning](IMAGE_SCANNING.md).

## Licence

THIS INFORMATION IS LICENSED UNDER THE CONDITIONS OF THE OPEN GOVERNMENT LICENCE found at:

<http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3>

The following attribution statement MUST be cited in your products and applications when using this information.

> Contains public sector information licensed under the Open Government license v3

### About the licence

The Open Government Licence (OGL) was developed by the Controller of Her Majesty's Stationery Office (HMSO) to enable information providers in the public sector to license the use and re-use of their information under a common open licence.

It is designed to encourage use and re-use of information freely and flexibly, with only a few conditions.
