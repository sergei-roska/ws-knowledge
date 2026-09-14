---
name: local-memory-search
description: Query a project-scoped local code-memory index through the read-only local-memory-search MCP server, choosing safe retrieval tools, inspecting degradations, and routing writes elsewhere.
---

# Local Memory Search

## Decisions (frozen)

- This server is the read-only consumer of shared LanceDB and SQLite project data; index creation, repair, and deletion belong to `local-memory-indexer`. [grounded: sources/local-memory-search/SKILL.md:1.1-1.4, 3.4]
- Use an absolute `project_path` on every call. Relative paths are resolved against the server process current directory, and the server's traversal check is ineffective. [grounded: sources/local-memory-search/SKILL.md:1.5; references/limits-and-blindspots.md:543-552]
- Inspect `data.error_code` and `warnings`, not only MCP `isError`; ordinary domain failures and degraded results can arrive in a normal envelope. [grounded: sources/local-memory-search/SKILL.md:3.9; references/tool-catalog.md:15-36]
- Do not page a search request beyond `pagination.total_returned`; an offset past available non-empty results can return `INTERNAL_ERROR`. [grounded: references/limits-and-blindspots.md:250-290]
- Do not poll `health_check`: it makes an OpenRouter embedding probe when a key is available. Use `index_status` as the default pre-search diagnostic. [grounded: sources/local-memory-search/SKILL.md:3.1, 4.5; references/limits-and-blindspots.md:223-249]

## Trigger & Activation

- Invoke for hybrid, semantic, or keyword code search; chunk/context retrieval; index-read diagnostics; and static call/import graph queries. [grounded: sources/local-memory-search/SKILL.md:2.1-2.4]
- Invoke `index_status` before a first search on an unfamiliar project to determine index readiness and available search modes. [grounded: sources/local-memory-search/SKILL.md:3.1]
- Do not invoke to index, re-index, repair, or delete project memory; route those requests to `local-memory-indexer`. [grounded: sources/local-memory-search/SKILL.md:3.4]
- Do not use `trace_path` for Drupal hook, service, route, config, or template reference edges; route those to `drupal-codebase-introspect:trace_code_references`. [grounded: sources/local-memory-search/SKILL.md:3.5]

## Input Contract

### Mandatory Parameters

- `intent` (string): `search`, `context`, `chunk`, `similar`, `diagnose`, or `graph`. [extrapolated: orchestration interface over grounded MCP tools]
- `project_path` (string): an absolute project root supplied on every call. [grounded: references/limits-and-blindspots.md:543-552]

### Optional Parameters

- `query` (string): required for `search_hybrid`, `search_semantic`, and `search_keyword`; select keyword search for exact machine names, symbols, FQCN fragments, and hook names. [grounded: sources/local-memory-search/SKILL.md:3.2]
- `chunk_id` (string): required by `get_chunk`, `read_chunk_neighbors`, and `explain_match`. [grounded: references/tool-catalog.md:173-229, 264-293]
- `file_path` (string): seed path for `search_similar`, or exact path for `get_import_graph`. [grounded: references/tool-catalog.md:231-263, 405-425]
- `source_symbol`, `target_symbol`, or `symbol` (string): graph lookup inputs. [grounded: references/tool-catalog.md:358-447]
- `filters`, `limit`, `offset`, `fields`, `exclude_fields`, and tool-specific options: apply only those accepted by the selected MCP tool. [grounded: references/tool-catalog.md:38-65, 67-447]

### Validation Constraints

- Require a non-empty query for a search. Reject non-ASCII token-only keyword queries as `UNSUPPORTED_QUERY` because tokenizer output may be empty without a server warning. [grounded: references/limits-and-blindspots.md:386-400]
- Use `search_semantic` only after `index_status` confirms usable vectors. [grounded: sources/local-memory-search/SKILL.md:3.3]
- Reject a positive `offset` unless a prior page-zero response establishes `offset < pagination.total_returned`. [grounded: references/limits-and-blindspots.md:250-290]
- Reject negative or zero `rrf_k`, and out-of-range ranking weights, before invoking search. The server schema permits unsafe values, including an `rrf_k` that serializes an infinite score as `null`. [grounded: references/limits-and-blindspots.md:291-319]

## Execution Algorithm

1. Validate the absolute path, intent, and selected tool inputs. Return `INVALID_INPUT` locally rather than relying on the server path guard. [extrapolated: client-side validation policy; grounded rationale: references/limits-and-blindspots.md:543-552]
2. For an unfamiliar project, call `index_status(project_path)`. Use `health_check` only when its external embedding probe is explicitly acceptable. [grounded: sources/local-memory-search/SKILL.md:3.1, 4.5]
3. Route `search` intent: use `search_keyword` for exact identifiers; use `search_semantic` only with available vectors; otherwise use `search_hybrid`. [grounded: sources/local-memory-search/SKILL.md:2.1, 3.2-3.3]
4. For a search response, return results, `strategy_weights.mode`, pagination, and warnings. Treat `keyword_only` or `sqlite_fallback` as degradation, and do not compare scores across modes. [grounded: references/limits-and-blindspots.md:207-221, 401-423]
5. For additional pages, increment only while the prior response reports `offset + limit < pagination.total_returned`; never send an offset at or beyond that total. [grounded: references/limits-and-blindspots.md:250-290]
6. Route `context` intent to `retrieve_context_pack`; report warnings because its `source_of_truth` does not reveal fallback mode. Use `rerank: true` only when OpenRouter network use is acceptable. [grounded: references/limits-and-blindspots.md:479-502; sources/local-memory-search/SKILL.md:2.5, 3.8]
7. Route `chunk` intent to `get_chunk` or `read_chunk_neighbors`; treat `CHUNK_NOT_FOUND` as a possible re-index race. Do not treat unknown `fields` as valid content because the server silently omits them. [grounded: references/limits-and-blindspots.md:447-478]
8. Route `similar` intent to `search_similar`; require a vector index and report `INDEX_UNAVAILABLE` without attempting a semantic fallback. [grounded: references/limits-and-blindspots.md:503-516]
9. Route `graph` intent to `find_callers`, `find_callees`, `get_import_graph`, or `trace_path`. State that graph tools operate on static indexed data and can return empty results when graph tables are absent. [grounded: sources/local-memory-search/SKILL.md:2.4; references/limits-and-blindspots.md:517-542]
10. After every tool call, inspect `data.error_code`, `warnings`, and mode. Return the raw tool payload with a normalized result status; never issue mutation tools through this server. [grounded: sources/local-memory-search/SKILL.md:1.3-1.4, 3.9]

## Output Schema

```json
{
  "type": "object",
  "required": ["status", "intent", "project_path", "result"],
  "properties": {
    "status": {"enum": ["SUCCESS", "DEGRADED", "NOT_INDEXED", "FAILED", "INVALID_INPUT"]},
    "intent": {"enum": ["search", "context", "chunk", "similar", "diagnose", "graph"]},
    "project_path": {"type": "string"},
    "result": {"type": "object"},
    "mode": {"type": "string"},
    "pagination": {"type": "object"},
    "warnings": {"type": "array", "items": {"type": "string"}},
    "error_code": {"type": "string"}
  }
}
```

[extrapolated: normalized client-facing result schema; source tools retain their individual response contracts]

## Edge Cases & Failure Modes

- The embedding or LanceDB vector leg can fail while search returns a keyword-only or SQLite fallback response; surface warnings and mode. [grounded: references/limits-and-blindspots.md:207-221, 401-423]
- `retrieve_context_pack(rerank=true)` uses OpenRouter's `/rerank`, not the tool schema's stated local model; rerank failures may only surface as a warning. [grounded: sources/local-memory-search/SKILL.md:2.5, 3.8; references/limits-and-blindspots.md:479-502]
- `doctor_index(auto_fix=true)` is read-only and its repair option is a no-op; route repairs to the indexer. [grounded: sources/local-memory-search/SKILL.md:3.6]
- Search cache entries persist for 60 seconds, including degraded or stale results; use the exposed `cache_bust` option where available. [grounded: references/limits-and-blindspots.md:424-446]
- `search_similar` seeds by suffix and selects the lowest-line chunk, so ambiguous basenames can select a different file than intended. [grounded: references/limits-and-blindspots.md:503-516]
- `trace_path` breadth-first traversal has no explicit cost cap; avoid it on an unbounded graph request. [grounded: references/limits-and-blindspots.md:517-542]

## Definition of Done (DoD)

- [ ] Every MCP call included an absolute `project_path`. [grounded: references/limits-and-blindspots.md:543-552]
- [ ] Search routing matched query intent and vector readiness. [grounded: sources/local-memory-search/SKILL.md:3.1-3.3]
- [ ] Responses were checked for `data.error_code`, warnings, and retrieval mode. [grounded: sources/local-memory-search/SKILL.md:3.9; references/limits-and-blindspots.md:207-221]
- [ ] Pagination stopped before `offset >= total_returned`. [grounded: references/limits-and-blindspots.md:250-290]
- [ ] No write, repair, reindex, or delete operation was sent to this server. [grounded: sources/local-memory-search/SKILL.md:3.4, 3.6]

## Candidates

- [extrapolated] Add a caller-side timeout, cancellation, and rate-limit policy; the server does not provide rate limiting or retry/backoff for OpenRouter calls.

## Open questions

- [grounded] The server documentation promises graceful degradation but an out-of-range pagination call can produce an internal error; upstream correction is required. [grounded: references/limits-and-blindspots.md:250-290]
- [grounded] The 128-character storage-slug truncation can theoretically collide for long project paths; it was inferred from code and not exercised live. [grounded: references/limits-and-blindspots.md:543-552]
