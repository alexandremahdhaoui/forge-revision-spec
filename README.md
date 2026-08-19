# forge-revision-spec

The `Revision` model and the state transport contract, with the conformance
vectors every state engine must pass.

## Why it is its own repo

forge-ci writes revisions. forge-factory reads them. **Neither depends on the
other.** They both depend on this.

Putting the contract in `forge-ci-spec` would make forge-factory look like it
depends on the pipeline, which it does not.

## What is here

| Path | Holds |
|---|---|
| `spec/revision.v1.yaml` | OpenAPI 3.0.3. The `Revision` model and the get, put and list transport. |
| `testdata/cases.json` | Conformance vectors. Schema shape, and transport behaviour. |
| `hack/validate.sh` | Checks the schema and the vectors agree. |

It is an OpenAPI document rather than a bare JSON Schema so `forge-dev` can
generate types from it.

## The two halves of the contract

**`schema`** holds documents that must validate and documents that must not.

**`transport`** holds operation sequences every engine must satisfy, whatever it
stores behind. `ci-state-git` writes files and commits them. A DynamoDB engine
would write items. Both must round-trip the same 22 operations.

The runner injects each engine's own `spec` into every operation, so nothing in
this file knows what a path or a table is.

## What the core model fixes, and what it does not

The schema fixes the shape of a revision. Each engine keeps a free-form `spec`
block for its own internals.

```yaml
ci-state-git:       { path: ../golden-state }
ci-state-dynamodb:  { table: ci-state, region: eu-west-1 }
```

Nothing in the core model knows about either.

## Running the gate

```sh
forge test-all
```
