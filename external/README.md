# external/

Read-only reference clones of other repositories — projects similar to this
one, or ones it must integrate with — kept here for **analysis and comparison
only**.

## Rules

- **Not dependencies.** The project builds and runs without anything in this
  directory. Nothing here is vendored, imported, submoduled, or copied into the
  codebase. Ideas are incorporated as designs, patterns, or properly versioned
  dependencies — never as copied trees.
- **Read-only.** Never edit a clone's contents; never commit them. Clones are
  ignored by the `.gitignore` next to this file; only it and this README are
  tracked.
- **Every clone is indexed.** Add a row to the table below in the same change
  that adds the clone, and remove the row when you delete the clone. The table
  is the manifest: a fresh checkout has an empty `external/`, so the row must
  hold enough to re-clone (origin URL + ref).
- **Every clone gets an analysis page** in
  [`doc/sources/`](../doc/sources/README.md), named
  `YYYY-MM-DD-<repo>-analysis.md`: what it is, what we learned, what we adopt
  or reject, and how it maps onto this codebase. The clone is raw material; the
  analysis page is what the wiki keeps.
- **Keep the ref current.** When you pull a clone forward, update its ref and
  date here and note what changed in the analysis page.

## Adding a clone

```shell
git clone <origin-url> external/<name>
git -C external/<name> rev-parse --short HEAD    # record this as the ref
```

Then add the row below and write the analysis page.

## Re-creating clones on a fresh checkout

```shell
git clone <origin-url> external/<name> && git -C external/<name> checkout <ref>
```

## Index of clones

| Directory | Origin URL | Ref | Cloned | Why it is here | Analysis |
|---|---|---|---|---|---|
| _none yet_ | | | | | |

## Related

- [AGENTS.md → Reference clones](../AGENTS.md#reference-clones-external)
- [doc/sources/](../doc/sources/README.md) — analysis pages
- [doc/runbooks/repo-hygiene.md](../doc/runbooks/repo-hygiene.md) — index drift check
