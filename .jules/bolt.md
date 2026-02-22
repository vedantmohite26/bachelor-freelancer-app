## 2025-05-15 - AI Response Latency & Caching
**Learning:** AI response latency is a significant bottleneck, often exceeding 1-2 seconds per request. Using highly granular timestamps (e.g., minute-level) in the AI context payload causes unnecessary cache misses for identical user queries within a short timeframe.
**Action:** Implement an LRU cache on the backend to store AI responses. On the frontend, truncate dynamic context fields like system timestamps to hour precision (YYYY-MM-DD HH:00) to maximize cache hit rates without sacrificing relevant temporal context.
