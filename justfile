# Looping Llama - Repository Verification Contract
set shell := ["bash", "-eo", "pipefail", "-c"]
export PATH := env_var('HOME') + "/.local/share/mise/shims:" + env_var('HOME') + "/.local/bin:" + env_var('PATH')

default: verify

# Unified entry point asserted by the orchestrator loop
verify: lint test

# Static analysis and syntax verification
lint: lint-shell lint-python lint-manifests

lint-shell:
    @echo "[LINT] Checking shell script syntax with bash -n..."
    @for f in bin/* install.sh scripts/*.sh; do \
        if [ -f "$f" ] && head -n 1 "$f" | grep -qE '^#!.*(bash|sh)'; then \
            bash -n "$f" || exit 1; \
        fi \
    done
    @echo "[OK] All shell scripts passed syntax checks."

lint-python:
    @echo "[LINT] Verifying Python scripts compilation..."
    @python3 -m py_compile bin/record-provenance scripts/lint-manifests.py || exit 1
    @echo "[OK] Python scripts compiled cleanly."

lint-manifests:
    @echo "[LINT] Validating TOML configs and manifests..."
    @python3 scripts/lint-manifests.py

# Smoke tests and functional checks
test: test-provenance test-review-contract

test-provenance:
    @echo "[TEST] Validating provenance JSON-LD schema generation..."
    @./bin/record-provenance --commit HEAD --task "Self-verification test" --output /tmp/prov-test.json
    @grep -q "ro-crate-metadata.json" /tmp/prov-test.json
    @rm -f /tmp/prov-test.json
    @echo "[OK] Provenance engine operates within spec."

test-review-contract:
    @echo "[TEST] Verifying adversarial reviewer empty diff handling..."
    @./bin/review "" 2>&1 | grep -q "\[BLOCK\]"
    @echo "[OK] Reviewer contract behaves deterministically."
