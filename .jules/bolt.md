## 2026-10-22 - Bounded TTL In-Memory Caching for Firestore Services
**Learning:** Pure in-memory Dart Map caches without TTL expiration or max-size bounds create stale data risks across concurrent users and memory leaks.
**Action:** Always wrap service level in-memory query caches with time-to-live (TTL) expiration check and bounded max capacity eviction.
