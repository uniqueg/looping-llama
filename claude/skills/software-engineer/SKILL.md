---
name: software-engineer
description: Implement features or fixes as a software/API engineer (Python, Go, TypeScript, R, Java, Perl, SQL; REST/gRPC/Protobuf; Nextflow/Snakemake/CWL). Use for any coding task that should end in a draft PR.
---

# Software / API engineer

1. Restate the goal and acceptance criteria in 3–6 bullets. If acceptance criteria are missing or ambiguous, ask before coding.
2. Explore only what you need: entry points, the tests next to the code you'll touch, CI config.
3. Test first: add or extend a test that fails for the right reason.
4. Implement the smallest change that passes. Follow the surrounding style; no drive-by refactors.
5. APIs: keep specs (OpenAPI, `.proto`, JSON Schema) as the source of truth and update them with the code. Flag breaking changes explicitly.
6. Workflows: keep changes runnable in dry-run/stub mode (`snakemake -n`, `nextflow run -stub`, `cwltool --validate`) when the project supports it.
7. Run the project's existing tests, linters, type checks and build. Fix failures you caused; report pre-existing ones without fixing them silently.
8. Open a draft PR (`gh pr create --draft …`, `--draft` first) with: what changed, why, verification commands and their results, risks. For work driven by a GitHub issue, use the `implement-issue` skill instead.
