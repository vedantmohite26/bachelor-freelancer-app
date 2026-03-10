## 2024-05-22 - AI Response Caching & Timestamp Normalization

**Learning:** Backend AI response caching efficiency is heavily impacted by the precision of temporal context (timestamps) provided by the frontend. Using minute-precision timestamps makes cache keys unique for almost every request, leading to low hit rates even for identical user queries.

**Action:** Truncate timestamps to hour precision (YYYY-MM-DD HH:00) in the frontend when sending requests for AI advice. This maintains sufficient context for financial reasoning while maximizing backend cache hits, significantly reducing latency and LLM API costs.
