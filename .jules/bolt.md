# Bolt's Journal - Performance Optimizations

## 2025-05-14 - AI Response Caching & Async I/O
**Learning:** AI response latency is a major bottleneck in financial assistants. Using an LRU cache combined with frontend timestamp truncation (hour precision) significantly improves cache hit rates without sacrificing advice quality. Switching to `AsyncInferenceClient` prevents blocking FastAPI workers.
**Action:** Always consider input normalization (like timestamp truncation) when implementing caches for AI responses to maximize efficiency.
