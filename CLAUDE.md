# CLAUDE.md

This repo owns the contract between forge-ci and forge-factory. Change it and
you change both.

Read ~/.claude/CLAUDE.md first. Those rules apply here.

## The vectors are the contract

`testdata/cases.json` is what an implementation is tested against. Adding a rule
to the schema without adding a vector means nothing checks it.

`transport` vectors are the important half. They are operation sequences, not
documents, because a state engine is judged on behaviour rather than shape.

## Two rules a state engine must not break

**A missing record is `found: false`, never an error.** Every pipeline meets an
empty store on its first run.

**A payload is a string.** A byte array marshals to base64 and the generated MCP
schema rejects it, which broke every state write while passing in process.
There is a vector for exactly that shape.

## It is OpenAPI on purpose

`spec/revision.v1.yaml` is an OpenAPI document rather than a bare JSON Schema so
`forge-dev` can generate types from `components.schemas`. Keep every type under
`components.schemas`, and keep a `Spec` schema even when an engine has no
configuration, because the generator emits `Validate` and `FromMap`
unconditionally.
