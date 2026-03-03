# Dry Run: Drupal API Patterns

## Example Task

Add a custom block that displays the 5 most recent published articles, with a settings form for the admin to choose the content type.

## Applied Workflow

1. Classify task: extends a system with variants → Plugin API (Block).
2. Block needs data from Entity API → inject `EntityTypeManagerInterface`.
3. Block has admin config → implement `blockForm()` / `blockSubmit()`.
4. Output is structured → render array with `#theme` and proper `#cache` metadata.
5. No routing needed (block is placed via Block Layout UI).
6. No hooks needed (self-contained plugin).

## API Surface Decisions

- Plugin API: `#[Block]` attribute with `ContainerFactoryPluginInterface` for DI.
- Entity API: entity query with `accessCheck(TRUE)`, `condition('status', 1)`.
- Render API: `#theme` pointing to a Twig template, cache tags `['node_list']` to auto-invalidate.
- Form API (within block): `blockForm()` for content type selector, `blockSubmit()` to persist.

## Expected Output

- `src/Plugin/Block/RecentArticlesBlock.php` — block plugin class.
- `templates/recent-articles-block.html.twig` — Twig template.
- `my_module.module` — `hook_theme()` to register the template (thin, no logic).
- No `.services.yml` needed (plugin DI via `create()` factory).
- Cache tags ensure block updates when any node changes.

## Verification

- Block appears in Block Layout UI under the declared category.
- Changing content type in block settings updates displayed content.
- Creating a new article invalidates cached block output.
- `drush cr` does not break block rendering.
