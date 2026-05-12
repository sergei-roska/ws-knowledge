# Dry Run: Drupal API Patterns

## Example Task
"Add a custom block that displays the 5 most recent published articles, and allow the admin to change the number of items."

## 1. Intent & Scope (Triggers)
- The task requires extending a system with a user interface component (Block).
- It involves user input for configuration (Block settings form).
- It involves data retrieval (Entity Query).
- It involves rendering output (Render Arrays).

## 2. Retrieval & Context Gathering (Pre-Execution)
Before writing the block, the agent runs searches to understand existing patterns:
- Search for `extends BlockBase` to find where existing blocks live (verifying the `src/Plugin/Block` namespace).
- Search for existing `hook_theme()` implementations in `.module` files to see where the template should be registered.

## 3. API Surface Decisions (Execution Gates)
- **Plugin API**: Use the `#[Block]` attribute. Implement `ContainerFactoryPluginInterface` for Dependency Injection.
- **Dependency Injection**: Inject `EntityTypeManagerInterface` via the `create()` method. **MUST NOT** use `\Drupal::entityTypeManager()`.
- **Form API**: Implement `blockForm()` and `blockSubmit()` to handle the "number of items" setting instead of building a separate config form.
- **Entity API**: Build the query to fetch articles. **MUST** include `->accessCheck(TRUE)` and `->condition('status', 1)`. Use `EntityViewBuilder` for rendering the nodes, or extract specific data to pass to a Twig template.
- **Render Arrays**: Wrap the output in a render array. **MUST** include `#cache` metadata (`tags => ['node_list:article']`) so the block invalidates correctly when articles change.

## 4. Expected Output Files
- `src/Plugin/Block/RecentArticlesBlock.php` (The block class with attributes, DI, query, and cache metadata).
- `my_module.module` (Added `hook_theme` entry for the custom template).
- `templates/recent-articles-block.html.twig` (The layout for the articles).

## 5. Agent Verification Checklist (Post-Execution Check)
- [x] Has Dependency Injection been used appropriately? (Yes, `create()` method implemented).
- [x] Is the entity query explicitly checking access? (Yes, `accessCheck(TRUE)` added).
- [x] Does the render block have cache metadata? (Yes, cache tags included).
- [x] Is there any business logic floating in the `.module` file? (No, only `hook_theme` definition is present).
