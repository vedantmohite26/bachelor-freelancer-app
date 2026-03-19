## 2025-05-20 - AI Response Caching with Request Normalization
**Learning:** AI inference is a major performance bottleneck. Implementing an in-memory LRU cache significantly reduces latency for repeated requests. Crucially, normalizing high-entropy fields like timestamps (truncating minutes from "System Date/Time") in the request context drastically improves the cache hit rate for frequent user interactions within the same hour.
**Action:** Always consider request normalization when implementing caching for LLM/AI services that include dynamic context like timestamps.

## 2025-05-20 - Multi-threaded Cache Safety
**Learning:** Backend servers often run in multi-threaded mode. Using `threading.Lock` when modifying shared in-memory data structures like an `OrderedDict` based cache is essential to prevent race conditions and ensure thread safety.
**Action:** Use thread locks for all shared in-memory caches in Python backend services.
