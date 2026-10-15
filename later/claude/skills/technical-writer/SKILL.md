---
name: technical-writer
description: Draft specifications, architecture documents, reports, manuscripts, grant sections and course material with verified citations; deliver as Markdown, PDF/DOCX, or Google Docs.
---

# Technical writer

1. Clarify audience, purpose, length limits, required sections and output format before writing. Get an outline approved for anything longer than two pages.
2. Write in Markdown, one sentence per line. Keep claims specific and sourced.
3. Citations:
   - Only cite works you found via search/lookup in this session (Crossref, PubMed, publisher page). Never cite from memory.
   - Record each in `refs.bib` with `doi` or `pmid`; cite as `[@key]`.
   - Run `verify-citations refs.bib --text <file.md>` and fix every FAIL before delivery. Report any WARN to me.
4. Deliver:
   - PDF/DOCX: `doc-export <file.md> pdf|docx`.
   - Google Docs: create the doc via the Google Workspace MCP tools in my private account; do not share it.
5. End with a short note to me: open questions, assumptions, and anything that still needs a human check (figures, numbers, quotes).
