# Policy configuration

[`vulnerability-policy.yml`](vulnerability-policy.yml) is the single source of truth for
how scan results gate the build. It replaces `.grype.yaml` and `.trivyignore`, which had
to be kept in step by hand and had drifted.

This page describes the format. It deliberately does not repeat the current contents,
because a hand-maintained copy of a list is exactly what goes stale. To see what is
configured right now:

```bash
yq '.gate' vulnerability-policy.yml
yq '.scopes[] | {"id": .id, "gate_from": .gate_from}' vulnerability-policy.yml
yq '.exceptions[] | {"id": .id, "owner": .owner, "review_by": .review_by}' vulnerability-policy.yml
```

## `gate`

```yaml
gate:
  severity: medium
  only_fixed: true
```

| Key | Meaning |
| --- | --- |
| `severity` | Lowest severity considered for blocking. One of `negligible`, `low`, `medium`, `high`, `critical`. |
| `only_fixed` | When `true`, findings with no upstream fix are reported but never block. |

## `scopes`

A scope narrows the gate for a class of finding matched by file path, rather than listing
each CVE.

```yaml
scopes:
  - id: example-scope
    paths:
      - "/opt/vendor/tools/**"
    gate_from: critical
    reason: >
      Why this component is lower risk, and what keeps it current.
```

| Key | Meaning |
| --- | --- |
| `id` | Short identifier, used in reports. |
| `paths` | Glob patterns matched against the artefact path. `**` crosses directories, `*` does not. |
| `gate_from` | Severity at which findings in scope start blocking again. |
| `reason` | Required. Why the reduced gate is justified. |

A scope lowers the gate; it does not remove it. Anything at or above `gate_from` still
blocks, so a scope cannot hide a severe finding.

This repository currently defines no scopes: the Alpine runtime carries no recurring class
of non-actionable finding that needs one.

## `exceptions`

For a single finding that cannot be fixed and does not belong to a class.

```yaml
exceptions:
  - id: CVE-2024-12345
    package: example-package
    reason: Not reachable in this image; upstream fix expected in 1.2.4.
    owner: "@team-or-person"
    review_by: 2026-03-01
```

| Key | Meaning |
| --- | --- |
| `id` | CVE or GHSA identifier. Aliases are resolved, so either vocabulary matches. |
| `package` | Optional. Restricts the exception to one package. |
| `reason` | Required. |
| `owner` | Required. Who is accountable for revisiting it. |
| `review_by` | Required. Date after which the exception stops applying. |

Once `review_by` passes, the exception no longer suppresses anything and the finding
blocks again. Expired exceptions, and exceptions matching nothing, are both called out in
the job summary so they can be removed.

## Changing the policy

Policy changes go through pull request review like any other change. The gate runs on the
pull request, so the effect of a change is visible in the job summary before it merges.
