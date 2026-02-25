## 2025-02-25 - Context Bucketing for Caching
**Learning:** Including high-precision timestamps (e.g., minutes) in AI request payloads effectively disables server-side caching as every request becomes unique.
**Action:** Truncate or "bucket" temporal context to the nearest hour (or other appropriate window) to maintain context while enabling high cache hit rates.
