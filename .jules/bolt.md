## 2026-03-01 - Avoid intermediate MapEntry list allocation in stream transformations
**Learning:** In Dart stream snapshot transformations, using `snapshot.docs.asMap().entries.map(...)` creates intermediate `MapEntry` allocations and iterable wrapper overhead on every stream update. Replacing it with a direct indexed `for` loop reduces garbage collection pressure and CPU overhead on snapshot emissions.
**Action:** Use standard indexed `for` loops instead of `.asMap().entries.map(...)` when transforming list items with indices in stream mappings.
