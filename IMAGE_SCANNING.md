# Image scanning

Every image is scanned by [Anchore Grype](https://github.com/anchore/grype) and
[Aqua Trivy](https://github.com/aquasecurity/trivy) on pull requests, on merge to `main`,
and nightly.

Both scanners run in report-only mode. A single policy,
[`vulnerability-policy.yml`](vulnerability-policy.yml), decides what blocks a build, and
[`.github/scripts/scan-gate.py`](.github/scripts/scan-gate.py) applies it to both sets of
results. That replaces the two hand-synchronised ignore lists this repository used to
carry, which drifted apart because Grype and Trivy identify the same vulnerability under
different IDs.

## What blocks a build

A finding blocks only when all of the following hold:

1. Its severity is at or above `gate.severity` (currently `medium`)
2. An upstream fix exists
3. No scope in the policy lowers the threshold for it
4. No unexpired exception covers it

Everything else is still listed in the job summary and published to code scanning; it
just does not fail the build.

### Why unfixed vulnerabilities do not block

If there is no fixed version available upstream, no change to this Dockerfile can resolve
the finding. Failing the build on it blocks delivery without improving the image. Those
findings are reported, and become blocking automatically as soon as a fix ships.

Every exclusion this repository previously carried was of exactly this kind, so
`only_fixed: true` replaced the whole list.

## Why `main` is never blocked

The gate fails pull requests but only warns on `main`. A rebuild of an unchanged commit
must produce the same result today as it did last week, and vulnerability feeds move
daily. Without this, an untouched `main` would start failing for reasons unrelated to any
change made here.

Two things keep that safe:

- **Pinned inputs.** The base images are pinned by digest and the exact versions are held
  in `image-matrix.json`, so the same commit builds the same image every time.
- **Nightly detection.** The nightly scan applies the same policy to the published images
  and raises a GitHub issue when something blocks, so nothing goes unnoticed. The
  auto-update workflow separately opens a pull request when a new base image is available,
  and that pull request *is* gated.

## Fixing a finding

In order of preference:

### 1. Fix it

Usually a newer base image. The auto-update workflow raises that pull request daily; you
can also run it manually from the Actions tab.

For an Alpine package that has a fix but is not yet in the base image, upgrade it in the
Dockerfile:

```dockerfile
RUN apk add --no-cache 'libssl1.1>1.1.1'
```

### 2. Add a scope

If a whole class of finding is not relevant, for example a component that is not on the
request path, add a `scope` to `vulnerability-policy.yml` rather than one entry per CVE.
Scopes are matched by file path and lower the gate rather than removing it, so genuinely
severe findings still block.

### 3. Add an exception

Last resort, for a specific finding with no fix path. Every exception needs an `id`, a
`reason`, an `owner` and a `review_by` date. Once `review_by` passes the exception stops
applying and the finding blocks again, so the list cannot quietly rot.

See [POLICY_CONFIGURATION.md](POLICY_CONFIGURATION.md) for the file format.

## Running the gate locally

```bash
pip install pyyaml
docker build --target production -t dotnetcore-local .

grype dotnetcore-local -o json --file grype.json
trivy image --format json --output trivy.json dotnetcore-local

python3 .github/scripts/scan-gate.py \
  --grype grype.json \
  --trivy trivy.json \
  --image dotnetcore-local
```

The script exits non-zero when something blocks, and prints the same report the workflow
puts in the job summary.
