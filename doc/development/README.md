# Development Documentation

Documentation for developers working on this project — setup, workflow, debugging, and internal guides.

## Quick Start

For new developers:

1. Read [CLAUDE.md](../../CLAUDE.md) for project conventions and tech stack.
2. Review the current [Roadmap](../plans/README.md) and active plans.
3. Check [Runbooks](../runbooks/README.md) for operational procedures.

## Naming Convention

Descriptive kebab-case filenames (e.g., `test-strategy.md`, `dependency-upgrade-guide.md`). Use date prefixes (`YYYY-MM-DD-`) for point-in-time documents like post-mortems or investigation logs.

## Index

| Document | Description |
|----------|-------------|
| [adopting-with-script.md](adopting-with-script.md) | Guide to using `adopt.sh` for template bootstrap automation |

## Bugs & Post-Mortems

**Detected bugs are tracked in `bd`, not here.** File each bug as a `bd` issue
(`bd create "..." --type bug`) so it gets dependencies, claims, and status. This
directory is the home for the *narrative* — a post-mortem written after a
significant bug is resolved.

- Naming: `YYYY-MM-DD-postmortem-<slug>.md`.
- Cross-link both ways: reference the `bd` ticket ID(s) in the post-mortem, and
  point the ticket back with `--external-ref` or the doc path.
- Suggested sections: Summary · Impact · Timeline · Root cause · Fix ·
  Prevention / follow-up tickets.

## Adding Documentation

Place developer-centric documents here:

- Setup and configuration guides
- Development workflow documentation
- Debugging guides and troubleshooting
- Investigation logs and post-mortems (see above)

## Related

- Wiki hub: [Overview](../overview.md) · [Index](../index.md) · [Status](../status.md)
- [System Architecture](../architecture/README.md)
- [Architecture Decisions](../decisions/README.md)
- [Implementation Plans](../plans/README.md)
- [Operational Runbooks](../runbooks/README.md)
