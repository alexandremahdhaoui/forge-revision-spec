#!/bin/sh
set -eu

exec uv run --quiet --with jsonschema --with pyyaml python3 - "$@" <<'PY'
import json
import sys

import yaml
from jsonschema import Draft202012Validator

spec = yaml.safe_load(open("spec/revision.v1.yaml"))
schemas = spec["components"]["schemas"]
cases = json.load(open("testdata/cases.json"))

failures = []


def inline(node, seen=()):
    if isinstance(node, dict):
        ref = node.get("$ref", "")

        if ref.startswith("#/components/schemas/"):
            name = ref.rsplit("/", 1)[1]

            if name in seen:
                return {"type": "object"}

            return inline(schemas[name], seen + (name,))

        return {k: inline(v, seen) for k, v in node.items()}

    if isinstance(node, list):
        return [inline(v, seen) for v in node]

    return node


def errors_for(schema_name, doc):
    if schema_name not in schemas:
        failures.append("no schema named %s" % schema_name)

        return []

    return list(Draft202012Validator(inline(schemas[schema_name])).iter_errors(doc))


for case in cases["schema"]["valid"]:
    errs = errors_for(case["schema"], case["doc"])

    if errs:
        failures.append("schema/valid/%s must pass %s but got: %s"
                        % (case["case"], case["schema"], errs[0].message))

for case in cases["schema"]["invalid"]:
    if not errors_for(case["schema"], case["doc"]):
        failures.append("schema/invalid/%s must fail %s and did not"
                        % (case["case"], case["schema"]))

tools = {"get", "put", "list"}

for case in cases["transport"]:
    if not case["ops"]:
        failures.append("transport/%s has no ops" % case["case"])

    for i, op in enumerate(case["ops"]):
        if op["tool"] not in tools:
            failures.append("transport/%s op %d uses unknown tool %s"
                            % (case["case"], i, op["tool"]))

        if "want" in op and "wantError" in op:
            failures.append("transport/%s op %d wants both a result and an error"
                            % (case["case"], i))

for f in failures:
    print("FAIL " + f, file=sys.stderr)

print("checked %d schema vectors and %d transport cases over %d operations" % (
    len(cases["schema"]["valid"]) + len(cases["schema"]["invalid"]),
    len(cases["transport"]),
    sum(len(c["ops"]) for c in cases["transport"]),
))

if failures:
    sys.exit(1)

print("the schema and the vectors agree")
PY
