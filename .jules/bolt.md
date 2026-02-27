## 2025-05-15 - [Backend AI Caching and Async Optimization]
**Learning:** Implementing an in-memory LRU cache in the FastAPI backend combined with hour-precision timestamp truncation on the frontend significantly improves performance for repeated AI requests. The switch to `AsyncInferenceClient` also improves the server's ability to handle concurrent requests.
**Action:** Always consider the "temporal resolution" of context data when implementing caching for AI features. Reducing precision (e.g., to the hour) can drastically increase cache hit rates without degrading user experience.
