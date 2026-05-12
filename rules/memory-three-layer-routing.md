# Three-Layer Memory Routing

Use memory tools autonomously as one system with three layers.

## Layers

- `memory` = durable facts, preferences, decisions, invariants, relationships
- `local_rag` = docs, specs, READMEs, skills, references, notes
- `mcp-vector-search` = code, graph, architecture, impact, review, semantic code search

## Primary Routing

- If the question is about identity, continuity, user preferences, project decisions, or durable facts: start with `memory`
- If the question is about documentation, specs, workflows, or reference material: start with `local_rag`
- If the question is about code, dependencies, architecture, call flow, review, or implementation impact: start with `mcp-vector-search`

## Secondary Routing

- Pull from a second layer when the primary layer is incomplete
- Pull from the third layer only when it adds clear value
- Do not duplicate a full search across all three layers by default

## Boundary

- Do not store docs in `memory`
- Do not treat `local_rag` as a substitute for code graph analysis
- Do not store raw code facts in `memory` unless they represent a durable rule, decision, or invariant
