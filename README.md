# Workspace Knowledge Base

A collection of reusable AI agent skills. Each skill lives in its own directory under `skills/` and is defined by a `SKILL.md` file (frontmatter with `name` and `description`, followed by the instructions). Some skills also ship supporting files such as references or evaluation data.

## Skills

### Concurrency and orchestration
- `actor-model` - concurrent actor model with isolated inboxes and typed messages
- `supervisor-tree` - supervision trees with restart strategies
- `fork-join` - parallel fan-out with barrier synchronization
- `finite-state-machine` - deterministic multi-phase execution with explicit transitions
- `serial-item-processor` - sequential processing with strict per-item isolation
- `pipes-and-filters` - decoupled, stateless transformation stages
- `divide-and-conquer` - recursive decomposition into independent subproblems
- `raft-quorum-consensus` - quorum-based consensus for multi-agent decisions

### Reliability
- `circuit-breaker` - failure thresholds, cooldown probes, fallback routing
- `rate-limiter-throttler` - token bucket and sliding window rate limiting
- `idempotency-key-filter` - exactly-once semantics for tool calls and mutations
- `saga-transaction-manager` - multi-step operations with compensating actions
- `two-phase-commit` - atomic multi-file mutations with unanimous validation
- `dead-letter-queue` - isolation of failing tasks with diagnostic dumps
- `copy-on-write` - speculative editing in isolated copies
- `lru-context-pruner` - least-recently-used pruning of LLM working context

### Design and planning
- `design-by-contract` - preconditions, postconditions, and invariants
- `event-sourcing` - append-only event streams and deterministic replay
- `blast-radius-analyzer` - dependency-based write surface for a feature ticket
- `hierarchical-work-decomposition` - goal to master plan, milestones, epics, and tasks
- `investigate-before-asking` - answer clarifying questions from the repo before asking the user
- `mockup-to-spec` - implementation specs derived from a working mockup, with a coverage gate

### Code intelligence
- `codebase-indexing` - AST and semantic vector indexing via the local-memory-indexer MCP server
- `codebase-search` - hybrid vector and keyword search with caller and callee tracing
- `entity-query-analyzer` - static audit of Drupal EntityQuery and entity load patterns

### Drupal and PHP
- `performance-maintainability-drupal` - production-safe performance and maintainability review

### Agents
- `agent-factory` - orchestration for creating skills, prompts, and reviews

### Development environments
- `provision-ddev` - DDEV environment provisioning and verification
- `provision-lando` - Lando environment provisioning and verification
- `provision-local-platform` - orchestration across DDEV, Lando, and Docker Compose
