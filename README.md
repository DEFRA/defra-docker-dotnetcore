# Docker .NET

This repository contains .Net parent Docker image source code for Defra.

The following table lists the versions of .Net available, and the parent image they are based on:

| .Net version       | Parent image   |
| ------------------ | -------------- |
| 6.0.428            | 6.0-alpine3.21 |
| 8.0.408            | 8.0-alpine3.21 |

Two parent images are created from this repository:

- `defra-dotnetcore`
- `defra-dotnetcore-development`

It is recommended that services use [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build) to produce production and development images, each extending the appropriate parent, from a single Dockerfile.

[Examples](./example) are provided to show how parent images can be extended for different types of services. These should be a good starting point for building .NET services conforming to Defra standards.

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

Images should be tagged according to the Dockerfile version and the version of .Net on which the image is based. For example, for Dockerfile version `1.0.0` based on .Net `3.1.0`, the built image would be tagged `1.0.0-dotnetcore3.1.0`.

## Example file

[`example/Dockerfile`](example/Dockerfile) - This is an example project that consumes the parent images created by this repository.

## CI/CD

On commit GitHub Actions will build both `dotnetcore` and `dotnetcore-development` images for the .NET versions listed in the [image-matrix.json](image-matrix.json) file, and perform a vulnerability scan, as described below. 

In addition a commit to the master branch will push the images to the `defradigital` organisation in GitHub using the version tag specified in the [JOB.env](JOB.env) file. The version is expected to be manually updated on each release.

The .Net version marked as latest in the [image-matrix.json](image-matrix.json) will be tagged as the latest image in Docker Hub.

## Image vulnerability scanning

A GitHub Action runs a nightly Anchore Grype scan of the image published to Docker, and will build and scan pre-release images on push.

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
