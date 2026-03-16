## 2026-03-16 - AI Response Caching
**Learning:** AI response latency is a major bottleneck. Implementing an LRU cache with input normalization (truncating minutes from timestamps) significantly improves response times for repeated queries.
**Action:** Use LRUCache and regex-based normalization for high-entropy context fields in AI services.
