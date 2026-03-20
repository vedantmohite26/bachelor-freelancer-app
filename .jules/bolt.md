## 2024-05-20 - Backend AI Caching & Timestamp Normalization
**Learning:** AI contexts often include high-entropy fields like current timestamps (HH:mm) which make standard request caching ineffective as the key changes every minute.
**Action:** Always normalize or coarsen high-entropy context fields (like timestamps) before generating cache keys to maximize hit rates for frequent interactions. In this case, coarsening to hour precision (HH:00) provided a reliable cache hit window for repetitive queries.
