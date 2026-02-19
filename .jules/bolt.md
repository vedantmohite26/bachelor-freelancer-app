# Bolt's Journal ⚡

## 2025-05-15 - AI Response Path Optimization
**Learning:** Truncating system timestamps in AI context payloads significantly increases backend cache hit rates. For a financial assistant, hour-precision (YYYY-MM-DD HH:00) is sufficient context while allowing identical requests from different users or sessions to be served instantly from an LRU cache.
**Action:** Always consider payload normalization (like timestamp truncation) when implementing caching for LLM-based features.

## 2025-05-15 - Local-First Intent Handling
**Learning:** A "Local-Fallback" strategy (calling AI first, then local logic) is much slower for common intents than a "Local-First" strategy. Implementing a local recognizer that returns `null` for unhandled intents allows for instant responses to greetings and simple queries while seamlessly falling back to AI for complex ones.
**Action:** Use `generateLocalAdvice` with a nullable return type to implement early-exit for high-confidence local matches.
