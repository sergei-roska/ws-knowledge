---
name: drupal-migration
description: Build and manage Drupal 10/11 migrations using the Migrate API. Use when importing data from external sources, migrating between Drupal versions, writing custom source/process/destination plugins, or debugging migration issues.
---

# Drupal Migration

## Overview

Import, transform, and load data into Drupal using the Migrate API.
This skill covers migration YAML configuration, custom plugins, drush commands, and debugging strategies.

## Workflow

1. Define the data source.
Identify source type: CSV, JSON, database, XML, Drupal 7/8 database, or custom API.

2. Map source to destination.
Define field mappings and determine which process plugins are needed for data transformation.

3. Write migration YAML.
Create `migrate_plus.migration.{id}.yml` with source, process, and destination configuration.

4. Implement custom plugins (if needed).
Write source, process, or destination plugins for non-standard transformations.

5. Run and validate.
Execute migration with `drush migrate:import`, inspect with `drush migrate:status`, roll back with `drush migrate:rollback`.

## Migration YAML Structure

```yaml
id: my_articles
label: 'Import articles from CSV'
migration_group: my_group
source:
  plugin: csv
  path: /path/to/articles.csv
  ids: [id]
  header_offset: 0
process:
  title: title
  body/value: body
  body/format:
    plugin: default_value
    default_value: full_html
  field_category:
    plugin: entity_lookup
    entity_type: taxonomy_term
    bundle: category
    bundle_key: vid
    value_key: name
    source: category_name
  uid:
    plugin: default_value
    default_value: 1
destination:
  plugin: 'entity:node'
  default_bundle: article
migration_dependencies: {}
```

## Source Plugins

- `csv` — CSV files (requires `migrate_source_csv`).
- `url` — JSON/XML from HTTP endpoints (requires `migrate_plus`).
- `d7_node` — Drupal 7 nodes (core migrate_drupal).
- `embedded_data` — inline data array for small/static datasets.
- Custom: extend `SourcePluginBase`, implement `initializeIterator()`, `fields()`, `getIds()`.

## Process Plugins (commonly used)

- `get` — direct field copy (implicit default).
- `default_value` — set a constant value.
- `migration_lookup` — reference entity from another migration.
- `entity_lookup` / `entity_generate` — find or create referenced entities.
- `skip_on_empty` / `skip_on_value` — conditional row/field skipping.
- `extract` — get value from array by index.
- `concat` — join multiple source values.
- `format_date` — date format conversion.
- `callback` — invoke any PHP callable.
- `sub_process` — process arrays/multi-value fields.
- Custom: extend `ProcessPluginBase`, implement `transform()`.

## Destination Plugins

- `entity:node`, `entity:taxonomy_term`, `entity:user`, etc.
- `entity_reference_revisions:paragraph` — for Paragraphs.
- Custom: extend `DestinationBase` (rare — use entity destinations when possible).

## Custom Source Plugin

```php
namespace Drupal\my_module\Plugin\migrate\source;

use Drupal\migrate\Plugin\migrate\source\SourcePluginBase;
use Drupal\migrate\Row;

#[\Drupal\migrate\Attribute\MigrateSource(
  id: 'my_api_source',
)]
final class MyApiSource extends SourcePluginBase {
  public function initializeIterator(): \Iterator {
    // Fetch data from API, return iterator of rows.
  }

  public function fields(): array {
    return [
      'id' => $this->t('Record ID'),
      'title' => $this->t('Title'),
    ];
  }

  public function getIds(): array {
    return ['id' => ['type' => 'integer']];
  }

  public function __toString(): string {
    return 'My API Source';
  }
}
```

## Drush Commands

```bash
# Check migration status
drush migrate:status

# Run a specific migration
drush migrate:import my_articles

# Run with update (re-process previously imported)
drush migrate:import my_articles --update

# Roll back a migration
drush migrate:rollback my_articles

# Reset stuck migration
drush migrate:reset-status my_articles

# Run all migrations in a group
drush migrate:import --group=my_group
```

## Migration Dependencies

- Use `migration_dependencies.required` for strict ordering.
- Use `migration_dependencies.optional` for soft dependencies.
- Reference migrations in `migration_lookup` process plugin.

## Required Checks

- Migration YAML has unique `id` and correct `source`/`process`/`destination`.
- Source plugin `getIds()` returns correct primary key definition.
- Process pipeline handles missing/null values with `skip_on_empty`.
- Referenced migrations exist and run before dependent ones.
- Rollback works cleanly without orphaned data.
- Migration is idempotent — re-running with `--update` produces correct results.

## Anti-Patterns

- Processing data in hooks instead of using process plugins.
- Hardcoding file paths in migration YAML instead of using configuration.
- Not defining `migration_dependencies` for related migrations.
- Using `entity_generate` without validating created entities.
- Ignoring rollback behavior — ensure clean data removal.
- Running migrations without `--limit` on first test against large datasets.

## References

- Read `references/migration-patterns.md` for YAML and plugin templates.
- Read `references/dry-run.md` for a worked migration example.
