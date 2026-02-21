## 2025-05-14 - [Timestamp Normalization for AI Caching]
**Learning:** AI responses often include the current date/time in the prompt. If the frontend sends high-precision timestamps (e.g., minutes/seconds), identical user queries will never hit the backend cache because the context string changes every minute. Truncating the timestamp to hour precision dramatically increases cache hit rates while maintaining sufficient temporal context for financial advice.
**Action:** Always normalize or bucketize temporal context data before using it as part of a cache key for AI responses.
