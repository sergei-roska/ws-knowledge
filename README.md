# Workspace Knowledge Base & AI Agent Skills

This repository serves as a central knowledge base, a collection of specifications, and a toolkit for efficient development (primarily Drupal, React, Tailwind) and AI agent context management.

## 📂 Project Structure

### 🧠 Skills (`skills/`)
Over 30 specialized skills for AI agents, grouped by domain:
- **Drupal & PHP:** SDC (Single Directory Components), migrations, architectural patterns, PHP 8.4, security audits.
- **Frontend & Design:** Tailwind CSS v4, Figma (integration and implementation), UI/UX standards, React/Next.js.
- **Data & Platform:** Supabase/PostgreSQL, Vercel, Azure/Acquia CI/CD.
- **AI & Workflow:** Documentation processing (OpenAI), knowledge management (Knowledge Graph), memory orchestration.

### 📜 Rules (`rules/`)
Architectural policies and invariants:
- **Anti-overengineering:** Three levels of strictness (soft, strict, paranoid) to prevent redundant solutions.
- **Drupal SDC Discipline:** Strict rules for asset management, composition, and component schemas.
- **Memory Policy:** Guidelines for memory recording and routing (Memory Write Policy, Three-layer Routing).

### ⚙️ Workflows (`workflows/`)
A collection of 20+ scripts and guides for automation:
- **Drupal DevOps:** Deployment (`drupal-deploy.sh`), database reset (`db-reset.sh`), configuration export.
- **Git Flow:** Feature start (`feature-start.sh`), synchronization with mainline (`sync-main.sh`), change pushing.
- **Smart Scripts:** Advanced tools for refactoring (`smart_refine.sh`), prompt management (`smart_promptify.sh`), and regex operations.
- **Analysis:** Code quality checks (`phpcs-check.sh`) and security audits.

### 📝 Specifications
Key specifications located in the root directory:
- `spec-codex-model-selection.md` — Choosing coding models.
- `spec-implementation-spec-authoring.md` — Standards for authoring implementation specs.
- `spec-skill-evaluation.md` — Skill evaluation methodology.

## 🧠 Memory System

The project implements a hybrid context management system:
1. **Knowledge Graph** — Structural relationships between entities and documentation.
2. **Vector Search (LanceDB)** — Semantic search across code and patterns using Tree-sitter for AST-aware chunking.
3. **Local RAG** — Full-text search across archives and documentation.

## 🚀 Usage

1. **MCP Configuration:** Core servers (vector-search, memorygraph, n8n) are configured in `scripts/mcp/mcp.json`.
2. **Local Index:** The vector search index is stored in `.mcp-vector-search/` and `lancedb/` (ignored by git).
3. **Command Line:** Use scripts from the `workflows/` directory for daily operations. It is recommended to add the `workflows/` path to your `$PATH`.
