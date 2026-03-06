## 2025-05-15 - AI Context Caching & Timestamp Precision
**Learning:** High-precision timestamps (e.g., YYYY-MM-DD HH:mm:ss) in AI context strings act as cache busters for backend AI response caching, even when the underlying financial data hasn't changed. In this codebase, the frontend was sending minutes in the system context.
**Action:** Truncate timestamps to the necessary precision (e.g., hour) and ensure consistent string formatting (padding) on the frontend to maximize backend cache hit rates for AI-generated advice.
