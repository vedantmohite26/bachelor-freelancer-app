## 2025-10-27 - Cache hit maximization through client-side normalization
**Learning:** In LLM-based applications, including the current timestamp in the prompt is crucial for context but kills backend cache hit rates. By normalizing the timestamp to hour-precision (YYYY-MM-DD HH:00) on the client side, we can achieve high cacheability for identical or similar requests within the same hour without losing significant financial context.
**Action:** Always consider the "entropy" of the request payload. Identify high-variance fields (like precise timestamps) that can be discretized or normalized to increase cache hit probability.

## 2025-10-27 - Asynchronous AI inference for backend concurrency
**Learning:** Using synchronous inference clients in a FastAPI/Uvicorn environment blocks the event loop, limiting the server to one concurrent AI request per worker.
**Action:** Always use `AsyncInferenceClient` and `async` route handlers for AI endpoints to ensure the server remains responsive during high-latency network calls to model providers.
