## 2025-03-09 - AI Backend Performance Optimization

**Learning:** Transitioning from synchronous to asynchronous processing with `AsyncInferenceClient` significantly improves concurrent request handling for I/O-bound AI tasks. Coupled with a server-side LRU cache and intentional timestamp truncation on the frontend, we can drastically reduce latency and operational costs for repeated queries.

**Action:** For all AI-integrated features, implement asynchronous request handling and design a caching strategy that balances context freshness with cache hit rates (e.g., truncating high-precision timestamps).
