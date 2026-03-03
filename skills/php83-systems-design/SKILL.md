---
name: php83-systems-design
description: Architect Drupal services and plugins using modern PHP 8.3 features, strict typing, and dependency injection. Use when creating or refactoring services, plugins, controllers, or any PHP class in Drupal projects.
---

# PHP 8.3 Systems Design for Drupal

## Overview

Implement technical logic using PHP 8.3 standards to ensure maximum safety, clarity, and performance.
This skill prioritizes architectural patterns over legacy Drupal hooks and global state.

## Core Patterns

### 1. Strict Typing
- Always declare `declare(strict_types=1);` as the first statement.
- Use full type hints for all parameters, return types, and properties.
- Use union types (`string|int`) and intersection types (`Countable&Iterator`) where appropriate.
- Use `never` return type for methods that always throw or exit.

### 2. Constructor Property Promotion
- Use promoted properties for DI to reduce boilerplate.
- Combine with `readonly` for immutable service dependencies.
```php
public function __construct(
  protected readonly EntityTypeManagerInterface $entityTypeManager,
  protected readonly LoggerInterface $logger,
) {}
```

### 3. Readonly Properties & Classes
- Declare services as `readonly class` if they are stateless (PHP 8.2+, Drupal 10.3+).
- Use `readonly` for value objects, DTOs, and event data.
- Readonly classes prevent accidental state mutation and improve static analysis.

### 4. Enums
- Use backed enums (`string` or `int`) for fixed state values instead of string constants.
- Use enum methods for behavior attached to states.
```php
enum ContentStatus: string {
  case Draft = 'draft';
  case Published = 'published';
  case Archived = 'archived';

  public function label(): string {
    return match($this) {
      self::Draft => 'Draft',
      self::Published => 'Published',
      self::Archived => 'Archived',
    };
  }
}
```

### 5. Match Expressions
- Use `match` instead of `switch` for type-safe, exhaustive comparisons.
- `match` is strict (`===`), returns a value, and throws on unmatched cases.
```php
$result = match($entity->bundle()) {
  'article' => $this->handleArticle($entity),
  'page' => $this->handlePage($entity),
  default => throw new \InvalidArgumentException("Unknown bundle: {$entity->bundle()}"),
};
```

### 6. Named Arguments
- Use named arguments for readability in methods with many parameters or boolean flags.
```php
$query->condition(field: 'status', value: 1);
$this->messenger()->addMessage(message: $this->t('Saved.'), type: 'status', repeat: FALSE);
```

### 7. Native PHP Attributes
- Use `#[Block]`, `#[Action]`, `#[QueueWorker]` attributes for plugin discovery (Drupal 10.2+).
- Transition from Doctrine annotations to attributes in all new code.

### 8. Typed Class Constants (PHP 8.3)
- Use typed constants for compile-time type safety.
```php
final class ApiClient {
  public const string BASE_URL = 'https://api.example.com';
  public const int TIMEOUT = 30;
  public const array ALLOWED_METHODS = ['GET', 'POST'];
}
```

### 9. Dependency Injection
- Never use `\Drupal::service()` inside classes that support DI.
- Use `create()` + `ContainerInterface` for plugins, `services.yml` for services.
- Favor Service Decoration when augmenting core behavior instead of wide hook overrides.
- Inject via interface types (`EntityTypeManagerInterface`), not concrete classes.

### 10. First-Class Callable Syntax
- Use `$this->method(...)` syntax for callbacks instead of string-based references.
```php
$items = array_filter($nodes, $this->isPublished(...));
```

## Rules

- Prefer class-based logic in `src/` over `.module` file procedural code.
- Ensure all new services are documented and type-safe for static analysis.
- Use Enums for fixed state values instead of arbitrary strings or class constants.
- Mark classes as `final` unless extension is an explicit design requirement.
- Use `match` over `switch` for value-returning conditional logic.

## Anti-Patterns

- Using `mixed` types without explicit documentation and justification.
- Leaking internal state through public mutable properties.
- Global scope dependency via `\Drupal` static calls in classes.
- Using string-based callbacks (`'className::method'`) instead of first-class callables.
- Untyped class constants.
- `switch` with fall-through behavior when `match` is cleaner.

## References

- Read `references/php83-patterns-ref.md` for condensed code patterns.
- Read `references/dry-run.md` for a worked refactoring example.
