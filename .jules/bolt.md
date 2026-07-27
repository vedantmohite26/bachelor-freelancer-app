## 2026-11-20 - Synchronous Error Handling in Dart Cached Futures

**Learning:** When caching asynchronous Future tasks (e.g. for request coalescing) in Dart, if a Future completes with an error, the Dart Zone system can flag it as an unhandled asynchronous error even if other microtasks or future callers subsequently handle it with try-catch blocks. To prevent this, a silent error handler like `future.catchError((_) => null)` must be synchronously registered on the Future immediately after creation. Additionally, in unit tests, using sequential try-catch blocks over asynchronous matchers ensures robust execution ordering during stub failures.

**Action:** Always call `future.catchError((_) => null)` synchronously right after instantiating any cached/shared asynchronous Future, and use synchronous try-catch blocks inside tests when asserting throwing behaviors to guarantee precise assertion execution order.
