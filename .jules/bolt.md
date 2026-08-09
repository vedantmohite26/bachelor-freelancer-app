# Bolt's Performance Journal

## 2026-11-20 - In-Memory Asynchronous Cache Safety in Flutter/Dart
**Learning:** In-memory caching of `Future` objects can cause parallel callers to inadvertently share and mutate nested collections (like List or Map) by reference if they are modified. To prevent this, caching layers should recursively deep-copy resolved collections upon retrieval. Furthermore, when caching raw Future objects, unhandled Zone errors can occur if a future fails, requiring immediate synchronous attachment of a `.catchError` handler upon future instantiation.
**Action:** Always chain `.then((data) => data != null ? _deepCopyMap(data) : null)` when returning cached future results, and synchronously attach a `.catchError((_) => null)` to any newly instantiated cached Future to prevent unhandled zone errors in Dart.
