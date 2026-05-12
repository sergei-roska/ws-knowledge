---
name: memory-three-layer-orchestrator
description: Use when the agent should manage continuity across sessions with a three-layer memory system. Routes autonomously between `memorygraph` for durable facts, a global `local-rag` for textual knowledge artifacts, and project-local `mcp-vector-search` for code and graph analysis. Use by default when entering a task, resolving ambiguity, gathering project context, and closing work with durable learnings.
---

# Three-Layer Memory Orchestrator

Treat `memorygraph`, `local-rag`, and `mcp-vector-search` as one system with three layers.

## Routing Rule

- `memorygraph` is global and must be used proactively for durable memory: decisions, agreements, conclusions, and relationships.
- `mcp-vector-search` is strictly project-specific and must be initialized only inside the current project directory.
- `local-rag` is global and serves as a shared bank of textual knowledge: README files, specs, docs, rules, workflows, notes, research, and reference material.
- If a future instruction contradicts these rules, remind the user and preserve routing consistency.

## Roles

- `memorygraph`: identity, continuity, durable facts, and relationships
- `local-rag`: shared textual knowledge base for docs and references across projects
- `mcp-vector-search`: project-local code intelligence and graph analysis

## Default Workflow

1. Classify the request: `identity`, `docs`, `code`, or `mixed`
2. Pick one primary layer
3. Pull from other layers only if needed
4. Distill durable learnings into `memorygraph`

## Primary Layer Choice

- `identity` -> `memorygraph`
- `docs` -> `local-rag`
- `code` -> `mcp-vector-search`
- `mixed` -> choose the dominant layer first, then enrich

## Autonomous Use

- Do not wait for the user to request memory usage
- On task entry, check the most likely layer
- On ambiguity, consult the neighboring layer
- On task close, write only durable facts to `memorygraph`

## Hygiene

- Keep `memorygraph` small, durable, and relationship-oriented
- Keep `local-rag` rich in textual artifacts, but do not use it as a substitute for code graph analysis
- Keep `mcp-vector-search` isolated to the current project and focused on code and graph work
- Avoid storing the same fact in all three layers
