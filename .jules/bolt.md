## 2026-10-12 - In-memory caching with deep copy protection for static data services
**Learning:** Returning cached mutable objects (`Map`, `List`) directly from service methods allows callers to accidentally mutate cached state in-place, leading to subtle state corruption across the app. Deep copying cached data structures before returning ensures thread-safe and reference-isolated cache reads.
**Action:** Always return deep copies (`map((x) => Map.from(x)).toList()`) when serving cached collections in Dart services.
