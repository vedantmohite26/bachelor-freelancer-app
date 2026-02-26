## 2026-02-26 - Backend Caching and Timestamp Normalization
**Learning:** High-resolution timestamps in LLM request payloads (e.g., minute-level) cause a near-zero cache hit rate because the input changes with every request. Truncating timestamps to the hour (coarsening) provides enough temporal context for financial advice while allowing massive cache hit improvements for repeated queries.
**Action:** Always consider the resolution of dynamic context fields in LLM requests. Use the coarsest resolution that still provides necessary accuracy to maximize caching benefits.
