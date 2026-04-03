# Review Guidelines

- You must write all code review feedback strictly in Korean.
- When generating a code review, you must not mention, summarize, quote, or restate any part of the review guidelines or their classification rules (e.g., P0, P1 criteria).
- The review output must contain only the actual feedback about the code, without including or referring to the guideline text itself.

## Architecture / Design

- You must classify clear violations of the project’s adopted architectural pattern (e.g., MVC, MVVM, VIPER, Clean Architecture) that significantly break layer boundaries or dependency direction as P0.
- You must classify cases where a ViewController, View, or UI layer component embeds substantial networking logic, persistence logic, or business rules in a way that meaningfully blurs architectural boundaries as P0.
Minor coordination logic or common MVC-style controller behavior should not automatically be classified as P0.
- You must classify clear and significant violations of the Single Responsibility Principle (SRP), where a type obviously mixes unrelated domains (e.g., UI rendering + networking + business rules), as P0.
- You must classify strong dependency direction violations that tightly couple high-level layers to concrete low-level implementations in a way that harms extensibility or testing as P0.

## Complexity / Control Flow

- You should classify excessively high cyclomatic complexity that meaningfully reduces readability or maintainability as P1.
- You should classify deeply nested or hard-to-follow control flow that makes reasoning about behavior difficult as P1.
- You should classify fragmented optional binding or guard/if nesting that noticeably harms readability as P1.

## Coupling / Testability

- You should classify structural designs that introduce tight coupling and make meaningful unit testing difficult as P1.
- You should classify direct use of global/shared dependencies (e.g., URLSession.shared, NotificationCenter.default, Date()) as P1 only when it significantly reduces testability or flexibility.
- You should classify reliance on global mutable state or singleton state as P1 when it introduces hidden side effects or nondeterministic behavior.

## Memory Management / ARC

- You must classify clear strong reference cycles that can cause memory leaks as P0.
- You should classify missing or incorrect capture lists in closures as P1 unless they demonstrably create a retain cycle.

## Error Handling

- You should classify swallowed errors (e.g., empty catch blocks, excessive use of try?) that obscure failure causes as P1.
- You must classify forced unwrapping that can realistically cause runtime crashes as P0.

## UIKit / UI Stability

- You should classify cell reuse mismanagement that can cause visible UI bugs or resource leaks as P1.
- You should classify UI state mutations from multiple uncontrolled sources as P1 when they can lead to inconsistent rendering.
- You should classify Auto Layout configurations that are likely to cause constraint conflicts or ambiguity at runtime as P1.

## Naming / Readability / Standards

- You should classify naming conventions that significantly obscure intent as P1.
- You should classify unnecessarily cryptic or overly condensed logic that meaningfully harms readability as P1.
- You should classify clear violations of the Swift API Design Guidelines or official Swift coding conventions as P1.

## Exceptions
- You should not review about below codes:
