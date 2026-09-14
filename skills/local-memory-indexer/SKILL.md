---
name: local-memory-indexer
description: Operate the local-memory-indexer MCP server to safely create, monitor, repair, resume, or deliberately remove a project-scoped code-memory index; never use it to search code.
---

# Local Memory Indexer

## Decisions (frozen)

- Use this server only as the write-side producer for one project's LanceDB and SQLite index; use `local-memory-search` for retrieval. [grounded: sources/local-memory-indexer/SKILL.md:1.1-1.3]
- Inspect `data.error_code` in every normal MCP response; expected domain failures use an `isError: false` envelope. [grounded: references/tool-catalog.md:35-46]
- Use a normalized absolute `project_path` with no NUL or `..` segment. [grounded: references/tool-catalog.md:49-60]
- Poll with both `run_id` and `project_path`; after `resume_indexing`, replace the tracked run ID with the returned ID. [grounded: references/tool-catalog.md:107-109, 281-302]
- Do not delete an index until status confirms that no run is `running`; deletion is recursive and has no concurrency-lock check. [grounded: references/tool-catalog.md:389-396]

## Trigger & Activation

- Invoke when the user asks to create or refresh a local project index, vectors are missing or stale, indexing must be monitored/paused/resumed, or index health requires diagnosis or repair. [grounded: sources/local-memory-indexer/SKILL.md:2.1-2.5]
- Do not invoke for semantic, keyword, symbol, graph, or context retrieval; this server exposes no retrieval tools. [grounded: sources/local-memory-indexer/SKILL.md:3.7]
- Do not invoke `delete_project_index` without explicit user intent to remove the project's stored index. [grounded: references/tool-catalog.md:362-396]

## Input Contract

### Mandatory Parameters

- `operation` (string): one of `start`, `status`, `pause`, `resume`, `doctor`, or `delete`. [extrapolated: orchestration interface over grounded MCP tools]
- `project_path` (string): normalized absolute project root for `start`, `doctor`, and `delete`; also supply it for `status` and `resume`. [grounded: references/tool-catalog.md:79, 122-126, 297-310, 373]

### Optional Parameters

- `run_id` (string): required for `pause`; required for `resume`; pair it with `project_path` for durable status polling. [grounded: references/tool-catalog.md:194, 273-277]
- `start_options` (object): `phases`, `force`, `include_globs`, `exclude_globs`, `max_file_size_kb`, `batch_size`, `enrich`, and `priority`. [grounded: references/tool-catalog.md:79-87]
- `auto_fix` (boolean, default `false`): permits `doctor_index` to change safe repair targets. [grounded: references/tool-catalog.md:309-310, 338-344]

### Validation Constraints

- Reject an empty, relative, NUL-containing, or non-normalized traversal path before the tool call. [grounded: references/tool-catalog.md:49-60]
- Reject `pause` without `run_id`; reject `resume` without `run_id`; reject unsupported operations. [grounded: references/tool-catalog.md:194, 273]
- For `delete`, require explicit deletion intent and a pre-delete status result that is not `running`. [grounded: references/tool-catalog.md:389-396]

## Execution Algorithm

1. Validate `operation`, `project_path`, and any required `run_id`. Return `INVALID_INPUT` locally without calling MCP on validation failure. [extrapolated: client-side validation policy]
2. For `start`, call `get_indexing_status(project_path)` to capture prior status and `index_provenance`. If no index/run exists, continue. If compatible data exists, retain its backend/model/dimension; vector spaces cannot be mixed. [grounded: references/tool-catalog.md:100-109, 586-595]
3. Call `start_indexing` with the supplied options. If enrichment is unavailable, retry once with `enrich: false`; otherwise return the structured failure. [grounded: references/tool-catalog.md:100-103, 595]
4. Save the returned `run_id`. If `status` is `already_running`, save the returned active run ID and poll it rather than issuing a duplicate start. [grounded: references/tool-catalog.md:89-95]
5. For `status`, call `get_indexing_status` with both identifiers. Treat `status`, not `phase`, as the completion indicator; report progress, warnings, and fatal `error` when present. [grounded: references/limits-and-blindspots.md:148-161]
6. For `pause`, call `pause_indexing(run_id)`. State that only embedding is actually pausable; discovery continues when paused during Phase 1. [grounded: references/tool-catalog.md:219-230; references/limits-and-blindspots.md:126-144]
7. For `resume`, call `resume_indexing(run_id, project_path)`, then replace `run_id` with `data.run_id` and poll the replacement. If enrichment is unavailable, start embedding directly with `start_indexing({ phases: ["embedding"], enrich: false })`. [grounded: references/tool-catalog.md:281-302; references/limits-and-blindspots.md:80-98]
8. For `doctor`, call `doctor_index(project_path, auto_fix)`. Report checks, issues, `auto_fixed`, and suggested actions. Invoke auto-fix only when requested because it can alter SQLite/LanceDB state. [grounded: references/tool-catalog.md:312-356]
9. For `delete`, make the required status check. If it is not running, call `delete_project_index(project_path)` and return its `deleted` or `not_found` result. [grounded: references/tool-catalog.md:375-396]
10. After every MCP call, inspect `data.error_code`. Handle `RUN_NOT_FOUND` by validating IDs/path; handle backend mismatch or unrecoverable LanceDB schema mismatch by reporting that deletion plus reindexing is required, never deleting automatically. [grounded: references/tool-catalog.md:35-46, 582-607]

## Output Schema

```json
{
  "type": "object",
  "required": ["status", "operation", "project_path", "result"],
  "properties": {
    "status": {"enum": ["SUCCESS", "IN_PROGRESS", "PAUSED", "FAILED", "INVALID_INPUT", "CONFIRMATION_REQUIRED"]},
    "operation": {"enum": ["start", "status", "pause", "resume", "doctor", "delete"]},
    "project_path": {"type": "string"},
    "run_id": {"type": "string"},
    "result": {"type": "object"},
    "error_code": {"type": "string"},
    "warnings": {"type": "array", "items": {"type": "string"}}
  }
}
```

[extrapolated: normalized client-facing result schema; server tool payloads retain their individual grounded contracts]

## Edge Cases & Failure Modes

- `ENRICHMENT_BACKEND_UNAVAILABLE`: retry `start_indexing` with `enrich: false`; do not use `resume_indexing` for this workaround because it hardcodes `enrich: true`. [grounded: references/tool-catalog.md:100-103, 281-302]
- `DATABASE_LOCKED`: wait 60 seconds, then resume using both IDs. [grounded: references/tool-catalog.md:582-589]
- `BACKEND_INDEX_MISMATCH`: report that the old vector space must be explicitly deleted before reindexing with different provenance. [grounded: references/tool-catalog.md:592-595]
- Long runs exceed the 10-minute lock TTL: avoid duplicate starts; narrow scope with `include_globs` when needed. [grounded: references/limits-and-blindspots.md:25-43]
- A status lookup after process restart can fail without `project_path`; always include it. [grounded: references/limits-and-blindspots.md:120-124]
- Do not infer completion from `phase: "completed"`; completion is `status: "completed"`. [grounded: references/limits-and-blindspots.md:154-161]

## Definition of Done (DoD)

- [ ] Requested operation used the matching MCP tool and a validated absolute path. [grounded: references/tool-catalog.md:49-60]
- [ ] Every response was checked for `data.error_code`. [grounded: references/tool-catalog.md:35-46]
- [ ] Active or resumed runs have their current `run_id` and are polled with both identifiers. [grounded: references/tool-catalog.md:107-109, 281-302]
- [ ] Any repair or deletion side effect was explicitly requested and its result was returned. [extrapolated: orchestration completion criterion]
- [ ] No retrieval request was routed to this write-only server. [grounded: sources/local-memory-indexer/SKILL.md:3.7]

## Candidates

- [extrapolated] Add a caller-provided polling interval and timeout policy; the source defines telemetry but no client polling cadence.

## Open questions

- [grounded] The server's lock age uses `started_at` rather than an activity heartbeat; long-running index concurrency remains an upstream engineering issue. [grounded: references/limits-and-blindspots.md:25-43]
- [grounded] `resume_indexing` cannot accept `enrich: false`; the direct embedding-start workaround remains required when enrichment is unavailable. [grounded: references/limits-and-blindspots.md:80-98]
