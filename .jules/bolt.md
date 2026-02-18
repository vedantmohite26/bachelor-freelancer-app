# Bolt's Performance Journal ⚡

## 2025-05-14 - AI Response Latency & Caching
**Learning:** LLM calls in the financial assistant are the primary source of latency (1-5s). Many queries are repetitive (greetings, status checks) or could be handled by local logic. Context strings that include high-precision timestamps (minutes/seconds) prevent effective backend caching.
**Action:** Implement a dual-layer optimization: (1) Local-first intent handling for common queries to skip network entirely, and (2) Backend LRU caching with stable context strings (truncated timestamps) to make repeated AI queries near-instant.
