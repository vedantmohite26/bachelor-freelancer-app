## 2025-05-15 - Async AI Response Caching
**Learning:** Implementing an asynchronous client and a caching layer for AI responses significantly reduces latency and server load. Normalizing timestamps in the context (e.g., truncating minutes) further increases the cache hit rate for periodic status checks.
**Action:** Always consider `AsyncInferenceClient` and request-based caching when integrating long-running AI API calls in a backend service.
