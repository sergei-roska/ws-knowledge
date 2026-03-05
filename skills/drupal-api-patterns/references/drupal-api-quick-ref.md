# Drupal API Quick Reference

## Code Shapes

### Service with DI (services.yml)

```yaml
services:
  my_module.example_service:
    class: Drupal\my_module\ExampleService
    arguments: ['@entity_type.manager', '@logger.factory']
```

### Service class

```php
declare(strict_types=1);

namespace Drupal\my_module;

use Drupal\Core\Entity\EntityTypeManagerInterface;
use Psr\Log\LoggerInterface;

final class ExampleService {
  public function __construct(
    protected readonly EntityTypeManagerInterface $entityTypeManager,
    protected readonly LoggerInterface $logger,
  ) {}
}
```

### Form (ConfigFormBase)

```php
namespace Drupal\my_module\Form;

use Drupal\Core\Form\ConfigFormBase;
use Drupal\Core\Form\FormStateInterface;

final class SettingsForm extends ConfigFormBase {
  protected function getEditableConfigNames(): array {
    return ['my_module.settings'];
  }

  public function getFormId(): string {
    return 'my_module_settings';
  }

  public function buildForm(array $form, FormStateInterface $form_state): array {
    $config = $this->config('my_module.settings');
    $form['api_url'] = [
      '#type' => 'url',
      '#title' => $this->t('API URL'),
      '#default_value' => $config->get('api_url'),
      '#required' => TRUE,
    ];
    return parent::buildForm($form, $form_state);
  }

  public function submitForm(array &$form, FormStateInterface $form_state): void {
    $this->config('my_module.settings')
      ->set('api_url', $form_state->getValue('api_url'))
      ->save();
    parent::submitForm($form, $form_state);
  }
}
```

### Route definition

```yaml
my_module.settings:
  path: '/admin/config/my-module/settings'
  defaults:
    _form: '\Drupal\my_module\Form\SettingsForm'
    _title: 'My Module Settings'
  requirements:
    _permission: 'administer site configuration'
```

### Controller with entity upcasting

```yaml
my_module.node_report:
  path: '/node/{node}/report'
  defaults:
    _controller: '\Drupal\my_module\Controller\ReportController::build'
    _title: 'Report'
  requirements:
    _entity_access: 'node.view'
  options:
    parameters:
      node:
        type: entity:node
```

### Block plugin (attribute, Drupal 10.2+)

```php
namespace Drupal\my_module\Plugin\Block;

use Drupal\Core\Block\Attribute\Block;
use Drupal\Core\Block\BlockBase;
use Drupal\Core\StringTranslation\TranslatableMarkup;

#[Block(
  id: 'my_module_example',
  admin_label: new TranslatableMarkup('Example Block'),
  category: new TranslatableMarkup('Custom'),
)]
final class ExampleBlock extends BlockBase {
  public function build(): array {
    return [
      '#theme' => 'my_module_example',
      '#data' => $this->getData(),
      '#cache' => [
        'tags' => ['node_list'],
        'contexts' => ['url.path'],
        'max-age' => 3600,
      ],
    ];
  }
}
```

### Event subscriber

```php
namespace Drupal\my_module\EventSubscriber;

use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\KernelEvents;

final class RequestSubscriber implements EventSubscriberInterface {
  public static function getSubscribedEvents(): array {
    return [
      KernelEvents::REQUEST => ['onRequest', 100],
    ];
  }

  public function onRequest(RequestEvent $event): void {
    // Logic here.
  }
}
```

### Thin hook in .module delegating to service (D10 pattern)

```php
use Drupal\my_module\Handler\NodeArticleEditFormHandler;

function my_module_form_node_article_edit_form_alter(&$form, FormStateInterface $form_state, $form_id): void {
  \Drupal::service('class_resolver')
    ->getInstanceFromDefinition(NodeArticleEditFormHandler::class)
    ->alterForm($form, $form_state, $form_id);
}
```

### Entity query (safe)

```php
$nids = $this->entityTypeManager
  ->getStorage('node')
  ->getQuery()
  ->accessCheck(TRUE)
  ->condition('type', 'article')
  ->condition('status', 1)
  ->sort('created', 'DESC')
  ->range(0, 10)
  ->execute();
```

### QueueWorker plugin (attribute, Drupal 10.3+)

```php
namespace Drupal\my_module\Plugin\QueueWorker;

use Drupal\Core\Queue\Attribute\QueueWorker;
use Drupal\Core\Queue\QueueWorkerBase;
use Drupal\Core\StringTranslation\TranslatableMarkup;

#[QueueWorker(
  id: 'my_module_sync',
  title: new TranslatableMarkup('My Module Sync'),
  cron: ['time' => 30],
)]
final class SyncWorker extends QueueWorkerBase {
  public function processItem($data): void {
    // Idempotent processing logic.
  }
}
```

### Render array with cache metadata

```php
$build = [
  '#theme' => 'item_list',
  '#items' => $items,
  '#cache' => [
    'tags' => ['node_list'],
    'contexts' => ['user.permissions'],
    'max-age' => 600,
  ],
];
```

## Cache Metadata Cheat Sheet

- `tags` — invalidate when specific data changes (`node:42`, `node_list`, `config:my_module.settings`).
- `contexts` — vary cache by request property (`user.permissions`, `url.path`, `languages:language_interface`).
- `max-age` — TTL in seconds (`0` = uncacheable, `-1` (Cache::PERMANENT) = permanent).
