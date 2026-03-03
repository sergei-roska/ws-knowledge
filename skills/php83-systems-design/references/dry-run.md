# Dry Run: PHP 8.3 Systems Design

## Example Task

Refactor a legacy Drupal service from procedural hook-based logic to modern PHP 8.3 class-based architecture.

## Before (legacy)

- Business logic inside `my_module.module` `hook_entity_presave()`.
- Uses `\Drupal::service()` static calls.
- String constants for status values (`'draft'`, `'published'`).
- Untyped properties, no `strict_types`.

## Applied Patterns

1. Extract logic into `src/EntityPresaveHandler.php` service.
2. Add `declare(strict_types=1)`.
3. Constructor property promotion with `readonly`.
4. Replace string constants with `ContentStatus` backed enum.
5. Replace `switch` with `match` expression.
6. Register service in `services.yml` with typed interface arguments.
7. Thin hook in `.module` delegates to `class_resolver`.

## After

```php
declare(strict_types=1);

final class EntityPresaveHandler {
  public function __construct(
    protected readonly EntityTypeManagerInterface $entityTypeManager,
    protected readonly LoggerInterface $logger,
  ) {}

  public function handle(EntityInterface $entity): void {
    if (!$entity instanceof NodeInterface) {
      return;
    }
    $action = match(ContentStatus::from($entity->get('field_status')->value)) {
      ContentStatus::Draft => $this->saveDraft($entity),
      ContentStatus::Published => $this->publish($entity),
      ContentStatus::Archived => $this->archive($entity),
    };
  }
}
```

## Verification

- PHPStan Level 8: passes with no errors.
- PHPCS Drupal,DrupalPractice: clean.
- Runtime behavior: identical to before — verified by existing tests.
- `\Drupal::service()` calls: 0 in refactored code.
