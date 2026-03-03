## 2025-02-17 - AI Backend Caching and Async Optimization
**Learning:** For AI-driven features, redundant requests with similar or identical context strings (e.g., timestamps) are a major source of latency. Truncating context timestamps to hour precision significantly improves cache hit rates without degrading the quality of advice. Using AsyncInferenceClient in a FastAPI backend is essential for high concurrency.
**Action:** Always consider if time-based context in LLM prompts can be coarsened to improve caching, and use asynchronous clients for network-bound AI tasks.
