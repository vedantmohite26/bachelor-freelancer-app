## 2024-05-20 - AI Response Caching with Timestamp Normalization
**Learning:** AI responses for financial advice often depend on the current time provided in the context. By normalizing this timestamp to hour precision (e.g., YYYY-MM-DD HH:00) when generating cache keys, we can significantly increase cache hit rates for users interacting with the assistant multiple times in a short period, without sacrificing the relevance of the advice.
**Action:** Always look for high-entropy fields in cache-key inputs (like timestamps or UUIDs) that can be normalized or bucketed to improve hit rates.
