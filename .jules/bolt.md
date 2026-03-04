## 2025-05-14 - AI Response Caching & Timestamp Truncation

**Learning:** Implementing a backend cache for AI responses is ineffective if the request payload contains highly granular timestamps (e.g., minute or second precision), as every request becomes unique. Truncating timestamps to hour precision on the frontend significantly increases the cache hit rate for identical user queries within the same temporal context without losing relevant "freshness" for financial advice.

**Action:** When caching time-sensitive AI responses, always evaluate the necessary precision of timestamps in the context and truncate them to the largest acceptable unit (e.g., hour) to maximize cache efficiency.
