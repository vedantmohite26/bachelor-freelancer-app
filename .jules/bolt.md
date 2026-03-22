## 2025-03-21 - [Context Normalization for AI Caching]
**Learning:** High-entropy fields in request payloads, such as high-precision timestamps (down to the minute or second), prevent effective caching even when the core data remains the same.
**Action:** Use regex to normalize these timestamps to a coarser precision (e.g., hour) before generating cache keys. This maintains sufficient context for the AI while dramatically increasing cache hit rates for frequent app interactions.
