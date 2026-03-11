## 2025-05-15 - AI Response Caching and Async I/O
**Learning:** Transitioning to `AsyncInferenceClient` and implementing a server-side LRU cache significantly improves backend responsiveness and reduces API costs. Truncating context timestamps to hour precision maximizes cache hit rates without losing relevant temporal context for financial advice.
**Action:** Always consider caching for deterministic or near-deterministic AI outputs and use async clients for network-bound AI requests to improve concurrency.
