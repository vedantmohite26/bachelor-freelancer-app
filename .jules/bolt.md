## 2026-03-12 - AI Backend Performance Optimization
**Learning:** The AI assistant's response time is a significant bottleneck. Using synchronous requests blocks the server, and lack of caching results in redundant LLM inferences for similar queries.
**Action:** Implement an asynchronous backend with an LRU cache and timestamp normalization to improve responsiveness and reduce API costs.
