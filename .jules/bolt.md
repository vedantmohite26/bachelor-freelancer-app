## 2025-02-12 - AI Response Caching Strategy
**Learning:** Truncating timestamps on the frontend (e.g., to hour precision) is critical for effective backend caching. Without it, the "noise" of ever-changing minutes/seconds causes cache misses even when the financial context remains effectively the same.
**Action:** Always coordinate frontend payload structure with backend caching logic to maximize hit rates.

## 2025-02-12 - Async LLM Handling
**Learning:** Migrating from synchronous to asynchronous LLM clients (like `AsyncInferenceClient`) significantly improves server throughput by not blocking the event loop during I/O-bound API calls.
**Action:** Use async handlers and clients for all external API integrations in FastAPI.
