## 2025-05-15 - AI Request Caching Strategy
**Learning:** For AI features that provide periodic advice (like financial tips), using minute-level timestamps in the context payload prevents effective backend caching. Truncating timestamps to hour-level precision (e.g., YYYY-MM-DD HH:00) allows for high cache hit rates without losing meaningful context for most business logic.
**Action:** Always consider the granularity of temporal context in AI requests and truncate to the coarsest level acceptable by the requirements to maximize efficiency.
