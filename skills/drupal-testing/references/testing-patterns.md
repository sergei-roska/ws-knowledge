# Testing Patterns

## Unit Test

```php
<?php

declare(strict_types=1);

namespace Drupal\Tests\my_module\Unit;

use Drupal\my_module\PayloadBuilder;
use Drupal\Tests\UnitTestCase;

final class PayloadBuilderTest extends UnitTestCase {

  protected PayloadBuilder $builder;

  protected function setUp(): void {
    parent::setUp();
    $this->builder = new PayloadBuilder();
  }

  public function testBuildReturnsExpectedStructure(): void {
    $result = $this->builder->build(['name' => 'Test']);
    $this->assertArrayHasKey('data', $result);
    $this->assertEquals('Test', $result['data']['name']);
  }

  public function testBuildWithEmptyInput(): void {
    $this->expectException(\InvalidArgumentException::class);
    $this->builder->build([]);
  }

}
```

## Kernel Test

```php
<?php

declare(strict_types=1);

namespace Drupal\Tests\my_module\Kernel;

use Drupal\KernelTests\KernelTestBase;
use Drupal\node\Entity\Node;
use Drupal\node\Entity\NodeType;

final class ArticleQueryTest extends KernelTestBase {

  protected static $modules = [
    'system',
    'node',
    'user',
    'field',
    'text',
    'my_module',
  ];

  protected function setUp(): void {
    parent::setUp();
    $this->installEntitySchema('node');
    $this->installEntitySchema('user');
    $this->installConfig(['my_module']);

    NodeType::create(['type' => 'article', 'name' => 'Article'])->save();
  }

  public function testPublishedArticlesQuery(): void {
    Node::create([
      'type' => 'article',
      'title' => 'Test',
      'status' => 1,
    ])->save();

    $service = $this->container->get('my_module.article_service');
    $results = $service->getPublishedArticles();
    $this->assertCount(1, $results);
  }

}
```

## Functional Test

```php
<?php

declare(strict_types=1);

namespace Drupal\Tests\my_module\Functional;

use Drupal\Tests\BrowserTestBase;

final class SettingsFormTest extends BrowserTestBase {

  protected static $modules = ['my_module'];

  protected $defaultTheme = 'stark';

  public function testSettingsFormAccess(): void {
    // Anonymous user should be denied.
    $this->drupalGet('/admin/config/my-module/settings');
    $this->assertSession()->statusCodeEquals(403);

    // Admin user should have access.
    $admin = $this->drupalCreateUser(['administer my module settings']);
    $this->drupalLogin($admin);
    $this->drupalGet('/admin/config/my-module/settings');
    $this->assertSession()->statusCodeEquals(200);
    $this->assertSession()->fieldExists('api_url');
  }

  public function testSettingsFormSubmission(): void {
    $admin = $this->drupalCreateUser(['administer my module settings']);
    $this->drupalLogin($admin);

    $this->drupalGet('/admin/config/my-module/settings');
    $this->submitForm([
      'api_url' => 'https://api.example.com',
    ], 'Save configuration');

    $this->assertSession()->pageTextContains('The configuration options have been saved.');
    $config = $this->config('my_module.settings');
    $this->assertEquals('https://api.example.com', $config->get('api_url'));
  }

}
```

## WebDriver Test

```php
<?php

declare(strict_types=1);

namespace Drupal\Tests\my_module\FunctionalJavascript;

use Drupal\FunctionalJavascriptTests\WebDriverTestBase;

final class AjaxWidgetTest extends WebDriverTestBase {

  protected static $modules = ['my_module', 'node'];

  protected $defaultTheme = 'stark';

  public function testAutocompleteField(): void {
    $admin = $this->drupalCreateUser(['access content']);
    $this->drupalLogin($admin);

    $this->drupalGet('/node/add/article');
    $page = $this->getSession()->getPage();
    $page->fillField('field_tags[target_id]', 'Ter');

    $result = $this->assertSession()->waitForElementVisible('css', '.ui-autocomplete li');
    $this->assertNotNull($result);
    $result->click();
  }

}
```
