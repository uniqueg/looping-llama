#!/usr/bin/env python3
"""PreToolUse hook: force an approval prompt for outward-facing MCP tool calls (R2).

Tool names differ between MCP servers, so match on verbs rather than exact names.
Anything not matched falls through to the normal permission rules.
"""
import json
import re
import sys

OUTWARD = re.compile(
    r"(share|permission|publish|send|reply|forward|invite|delete|trash|remove|"
    r"comment|post|merge|transfer|move)",
    re.IGNORECASE,
)

event = json.load(sys.stdin)
tool = event.get("tool_name", "")
# Only inspect the tool part of mcp__<server>__<tool>; server names may contain verbs.
action = tool.split("__", 2)[-1]
if OUTWARD.search(action):
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "ask",
                "permissionDecisionReason": f"Outward-facing action ({tool}) needs explicit approval.",
            }
        },
        sys.stdout,
    )
sys.exit(0)
