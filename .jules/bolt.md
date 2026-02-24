## 2025-05-14 - AI Response Caching & Frontend Timestamp Truncation
**Learning:** Backend caching of AI responses is ineffective if the request payload includes highly granular timestamps (e.g., minutes/seconds). Truncating these timestamps to hour precision on the frontend significantly increases cache hit rates without losing relevant temporal context for financial advice.
**Action:** Always coordinate client-side data formatting with backend cache key strategies, especially for LLM-based features.
