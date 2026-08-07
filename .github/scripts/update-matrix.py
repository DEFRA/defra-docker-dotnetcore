#!/usr/bin/env python3
"""Refresh image-matrix.json and the files that must agree with it.

Tracks the .NET SDK and runtime versions and the digests of both base images. The
digests are what make a rebuild of an unchanged commit reproducible, so they are
refreshed even when the version strings have not moved.

Writes `updated=true|false`, `title` and `body` to $GITHUB_OUTPUT when running in Actions.
"""

import json
import os
import re
import subprocess
import sys
import urllib.request

MATRIX = "image-matrix.json"
RELEASES_INDEX = (
    "https://raw.githubusercontent.com/dotnet/core/main/release-notes/releases-index.json"
)


def fetch_json(url):
    with urllib.request.urlopen(url, timeout=30) as response:
        return json.load(response)


def latest_dotnet_releases():
    index = fetch_json(RELEASES_INDEX)
    releases = {}
    for release in index["releases-index"]:
        releases[release["channel-version"]] = {
            "sdkVersion": release["latest-sdk"],
            "runtimeVersion": release["latest-runtime"],
        }
    return releases


def resolve_digest(reference):
    result = subprocess.run(
        ["docker", "buildx", "imagetools", "inspect", reference,
         "--format", "{{.Manifest.Digest}}"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    return result.stdout.strip() or None


def bump_patch(version):
    major, minor, patch = version.split(".")
    return f"{major}.{minor}.{int(patch) + 1}"


def replace_line(path, pattern, replacement):
    with open(path) as handle:
        content = handle.read()
    updated = re.sub(pattern, replacement, content, count=1, flags=re.MULTILINE)
    if updated != content:
        with open(path, "w") as handle:
            handle.write(updated)


def main():
    with open(MATRIX) as handle:
        matrix = json.load(handle)

    latest = latest_dotnet_releases()

    changes = []
    for entry in matrix:
        channel = entry["netVersion"]
        tag = f"{channel}-alpine{entry['alpineVersion']}"

        for field in ("sdkVersion", "runtimeVersion"):
            candidate = latest.get(channel, {}).get(field)
            if candidate and candidate != entry[field]:
                changes.append(
                    f"- .NET {channel} {field}: {entry[field]} -> {candidate}"
                )
                entry[field] = candidate

        for repo, field in (("aspnet", "runtimeDigest"), ("sdk", "sdkDigest")):
            reference = f"mcr.microsoft.com/dotnet/{repo}:{tag}"
            digest = resolve_digest(reference)
            if digest is None:
                print(f"{reference} could not be resolved; leaving {field} unchanged")
                continue
            if digest != entry.get(field):
                changes.append(f"- .NET {channel} {repo} digest: {tag} -> {digest}")
                entry[field] = digest

    if not changes:
        emit(False, "", "")
        print("No updates required.")
        return 0

    with open(MATRIX, "w") as handle:
        json.dump(matrix, handle, indent=4)
        handle.write("\n")

    with open("JOB.env") as handle:
        job_env = handle.read()
    current_version = re.search(r"DEFRA_VERSION=([\d.]+)", job_env).group(1)
    new_version = bump_patch(current_version)
    replace_line("JOB.env", r"^DEFRA_VERSION=.*$", f"DEFRA_VERSION={new_version}")

    default = next((e for e in matrix if e.get("latest")), matrix[-1])
    replace_line(
        "Dockerfile", r"^ARG DEFRA_VERSION=.*$", f"ARG DEFRA_VERSION={new_version}"
    )
    replace_line(
        "Dockerfile",
        r"^ARG BASE_VERSION=.*$",
        f"ARG BASE_VERSION={default['netVersion']}-alpine{default['alpineVersion']}",
    )
    replace_line(
        "Dockerfile",
        r"^ARG RUNTIME_DIGEST=.*$",
        f"ARG RUNTIME_DIGEST={default['runtimeDigest']}",
    )
    replace_line(
        "Dockerfile", r"^ARG SDK_DIGEST=.*$", f"ARG SDK_DIGEST={default['sdkDigest']}"
    )

    update_readme(matrix)

    versions = ",".join(e["netVersion"] for e in matrix)
    emit(True, f"Update .NET base image: {versions}", "\n".join(changes))
    print("\n".join(changes))
    return 0


def update_readme(matrix):
    with open("README.md") as handle:
        content = handle.read()

    for entry in matrix:
        content = re.sub(
            rf"(\|\s*{re.escape(entry['netVersion'])}\s*\|\s*)[\d.]+(\s*\|\s*)[\d.]+(\s*\|)",
            rf"\g<1>{entry['sdkVersion']}\g<2>{entry['runtimeVersion']}\g<3>",
            content,
        )

    with open("README.md", "w") as handle:
        handle.write(content)


def emit(updated, title, body):
    output = os.environ.get("GITHUB_OUTPUT")
    if not output:
        return
    with open(output, "a") as handle:
        handle.write(f"updated={str(updated).lower()}\n")
        handle.write(f"title={title}\n")
        handle.write("body<<POLICY_EOF\n")
        handle.write(body + "\n")
        handle.write("POLICY_EOF\n")


if __name__ == "__main__":
    sys.exit(main())
