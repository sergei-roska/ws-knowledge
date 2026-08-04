---
name: semantic-memory
description: Long-term semantic memory management using the memorygraph MCP server. Use when the agent needs to search or record durable architectural decisions, invariants, project incidents, domain glossary terms, or relationship graphs across sessions.
---

# Semantic Memory (Memorygraph MCP)

## Goal

Maintain project continuity across sessions using the `memorygraph` MCP server. Store high-level meaning, decisions, and constraints—never raw code diffs or transient debug noise.

---

## 1. Tool Integration (MCP `memorygraph`)

Use the installed `memorygraph` tools:
- `search_memories(query)` — Search memories by keyword/semantic query.
- `get_memory(memory_id)` — Retrieve full content and metadata of a specific memory.
- `store_memory(title, content, category, tags)` — Save a new durable memory entity.
- `create_relationship(source_id, target_id, relationship_type)` — Link two memories (`depends_on`, `constrains`, `motivates`, `supersedes`, `reverts`).
- `update_memory(memory_id, ...)` — Update status or content of an existing memory.

---

## 2. What Must Be Saved (Durable Knowledge)

Save to `memorygraph` ONLY if the fact satisfies at least two of these criteria:
1. **Architectural Decisions (ADRs):** Non-obvious architectural choices, trade-offs, and why alternative paths were rejected (`category: decision`).
2. **Project Invariants:** Strict project-wide rules, conventions, or constraints not inferable from code linters alone (`category: invariant`).
3. **Incidents & Reverts:** Production/staging failures, root causes, and lessons learned (`category: incident`).
4. **Domain Glossary & Aliases:** Project-specific terminology, module boundaries, or renamed concepts (`category: glossary`).

---

## 3. What Must NOT Be Saved (Transient Noise)

NEVER store in `memorygraph`:
- Raw code diffs or file listings (git history owns these).
- Transient debug output or temporary troubleshooting guesses.
- Routine minor refactors or everyday PR changes.
- Facts obvious from inspecting source code for 5 seconds.

---

## 4. Operational Workflow

### On Task Entry (Constraint & Context Search)
Before making architectural changes:
1. Query memory: `search_memories(query="<module_or_feature> constraint decision")`.
2. Inspect returned invariants or past incidents to avoid repeating previous mistakes.

### On Task Closure (Semantic Checkpoint)
Before completing a task with durable impact:
1. Formulate atomic, search-friendly memories.
2. Call `store_memory()` with clear `title`, `category`, and `tags`.
3. If replacing an old decision, mark the previous memory as `superseded` using `update_memory()` and link with `create_relationship()`.

---

## 5. Memory Entry Format

```json
{
  "title": "decision/http-only-session-cookie",
  "category": "decision",
  "tags": ["auth", "session", "cookie", "security"],
  "content": "Status: active | Scope: module/auth | Problem: Session desync on refresh | Decision: Use http-only cookies as canonical session store | Trade-off: Less client flexibility, stronger consistency."
}
```
