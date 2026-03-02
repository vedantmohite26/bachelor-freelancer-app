## 2025-05-22 - AI Backend Latency and Concurrency
**Learning:** AI responses are high-latency and expensive. Synchronous API calls block the entire event loop in FastAPI if not handled carefully.
**Action:** Use `AsyncInferenceClient` and `async def` for the endpoint to allow concurrent request handling. Implement an in-memory LRU cache to reuse responses for identical requests.

## 2025-05-22 - Improving Cache Hit Rate for AI prompts
**Learning:** Including high-precision timestamps (e.g., minutes/seconds) in AI prompts makes every request unique, effectively disabling any backend caching.
**Action:** Truncate context timestamps to hour precision (YYYY-MM-DD HH:00) on the frontend before sending to the backend to maximize cache hit probability without losing significant temporal context.
