# Evaluation Rubric and Model Difficulty

## What the evaluation rubric is
An evaluation rubric is the scoring framework you use to compare model outputs consistently.
It is not another implementation spec. It is the checklist and point system that tells you how to judge each answer.

A good rubric answers three questions:
- What categories are being judged?
- How important is each category?
- What does a high-score or low-score answer look like?

For this benchmark, the rubric should help compare both:
- standard implementation quality
- test-first engineering quality

## Suggested 100-point rubric

### 1. Architecture and Drupal correctness — 25 points
Evaluate:
- correct use of Drupal concepts
- realistic entity architecture
- proper use of services and DI
- no invented APIs or obviously broken structure

High score:
- strong Drupal-native structure
- sound separation of concerns
- correct routing/form/entity/service responsibilities

Low score:
- fake APIs
- confused content vs config concepts
- controller-heavy logic or unclear architecture

### 2. Entity design and data model — 15 points
Evaluate:
- field choices
- field types
- user references
- practical handling of status/priority/dates

High score:
- coherent field model aligned with requirements
- sensible defaults and field semantics

Low score:
- missing key fields
- poor type selection
- unclear ownership or entity responsibilities

### 3. Routing, forms, permissions, and links — 20 points
Evaluate:
- route coverage
- access control quality
- settings form correctness
- menu links, local actions, and local tasks consistency

High score:
- all required routes and UI integration pieces fit together
- permissions are applied thoughtfully

Low score:
- missing routes
- permissions defined but not used correctly
- local links/tabs inconsistent with route names

### 4. Config API and service design — 15 points
Evaluate:
- config schema thinking
- config read/write flow
- service boundaries
- runtime use of config values

High score:
- service reads config cleanly
- forms validate and persist config sensibly
- controllers remain thin

Low score:
- config is decorative only
- business logic is scattered
- service adds no real value

### 5. Tests quality — 15 points
Evaluate:
- appropriate test levels
- meaningful assertions
- coverage of critical behavior
- whether tests actually shape implementation

High score:
- clear difference between Unit, Kernel, and Functional concerns
- behavior-driven tests with real value

Low score:
- decorative tests
- class-existence checks only
- no link between tests and architecture

### 6. Completeness and consistency — 10 points
Evaluate:
- whether all required files are present
- internal naming consistency
- coherence between YAML, PHP, routes, permissions, and tests

High score:
- output feels complete and internally consistent

Low score:
- partial implementation
- mismatched names
- dangling references between files

## Difficulty estimate

### Standard Implementation Spec
Estimated difficulty: 7/10

Why:
- requires solid Drupal module architecture knowledge
- requires correct YAML and route wiring
- requires entity, service, config form, and permission design
- punishes shallow framework knowledge

### Test-Driven Implementation Spec
Estimated difficulty: 8.5/10

Why:
- includes everything from the standard spec
- adds test strategy and test-level judgment
- requires stronger architectural discipline
- exposes whether the model can design for testability

## Minimum model estimates
These are practical judgment calls, not vendor guarantees.

### OpenAI GPT-5 family
Official model family references:
- GPT-5: https://openai.com/index/introducing-gpt-5-for-developers
- GPT-5 mini: https://platform.openai.com/docs/models/gpt-5-mini
- GPT-5 nano: https://platform.openai.com/docs/models/gpt-5-nano

Estimated minimums:
- Standard Impl: `gpt-5-mini`
- Test-Driven Impl: `gpt-5`

Notes:
- `gpt-5-nano` is unlikely to be reliable for this benchmark
- `gpt-5-mini` may produce a usable Test-Driven answer, but with higher risk of decorative tests and architecture drift

### Google Gemini family
Official model references:
- Gemini models overview: https://ai.google.dev/models/gemini
- Gemini API model docs: https://ai.google.dev/gemini-api/docs/models/gemini-v2

Estimated minimums:
- Standard Impl: `Gemini 2.5 Flash`
- Test-Driven Impl: `Gemini 2.5 Pro`

Notes:
- `Gemini 2.5 Flash-Lite` is probably too weak as the primary candidate for this benchmark
- `Gemini 2.5 Pro` is the safer pick for test-first work

### Gemma family
Official model references:
- Gemma 3 announcement: https://developers.googleblog.com/en/introducing-gemma3/
- Gemma docs: https://ai.google.dev/gemma/docs/core
- Gemma 3 model card: https://ai.google.dev/gemma/docs/core/model_card_3

Estimated minimums:
- Standard Impl: `Gemma 3 12B IT`, more realistically `Gemma 3 27B IT`
- Test-Driven Impl: `Gemma 3 27B IT`

Notes:
- `1B` and `4B` are not realistic for a reliable Drupal benchmark of this size
- `12B` may handle Standard Impl with a tightly constrained prompt and format
- test-first Drupal work is much more demanding for open-weight models

## Practical interpretation
If your goal is to compare models on realistic Drupal usefulness, the likely floor is:
- Standard Impl: `gpt-5-mini`, `Gemini 2.5 Flash`, `Gemma 3 12B/27B`
- Test-Driven Impl: `gpt-5`, `Gemini 2.5 Pro`, `Gemma 3 27B`

If your goal is not just completion but clean, reviewable, Drupal-native output, you should expect the best results from the stronger non-lite variants.
