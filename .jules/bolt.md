## 2025-05-14 - AI Response Caching with Timestamp Normalization
**Learning:** High-entropy fields like timestamps in AI context strings severely reduce cache hit rates. By normalizing these timestamps to a coarser granularity (e.g., hour precision), we can significantly increase cache hits for repetitive user queries within a session without losing relevant context.
**Action:** Always identify and normalize high-entropy, low-relevance fields in request payloads before generating cache keys for LLM responses.
