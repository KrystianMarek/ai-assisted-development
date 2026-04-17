# Runbooks

Operational runbooks for this project. Each runbook captures the **exact commands that work** in production, including gotchas and troubleshooting steps discovered during setup.

These are living documents — update them when configuration changes.

## Naming Convention

`<procedure-name>.md` — descriptive kebab-case (e.g., `deploy-production.yml`, `rotate-secrets.md`, `db-restore.md`).

## Index

| Runbook | Description |
|---------|-------------|
| _none yet_ | — |

## Runbook Template

````markdown
# <Procedure Name>

## Purpose
What problem this runbook solves.

## When to Use
Trigger conditions or schedule.

## Prerequisites
- Credentials, tools, access

## Procedure

### Step 1 — <Action>

```shell
# exact command
```

Expected output:

```
...
```

### Step 2 — <Action>
...

## Verification
How to confirm the procedure succeeded.

## Rollback
How to undo if something goes wrong.

## Gotchas
Known failure modes and fixes.
````

## Related

- [Implementation Plans](../plans/README.md)
- [System Architecture](../architecture/README.md)
