# ⚡ Bolt's Performance Journal

## 2024-05-20 - AI Response Caching & Timestamp Normalization
**Learning:** External AI inference calls are the primary latency bottleneck. Caching identical requests is effective, but high-entropy fields like "System Date/Time" prevent cache hits even for conceptually identical user queries within the same hour.
**Action:** Implement an LRU cache with key normalization (truncating minutes from timestamps) to maximize reuse and reduce latency from ~2-5s to <10ms.
