## 2025-05-14 - AI Response Caching with Timestamp Normalization
**Learning:** AI context often includes high-entropy fields like timestamps ("System Date/Time: 2023-10-27 10:15"). Even if the user message is identical, the shifting timestamp causes cache misses. Normalizing these to a coarser precision (e.g., hour) maintains enough context for the AI while maximizing cache hits for frequent interactions.
**Action:** When implementing caching for LLM-based features, identify and normalize dynamic context fields that don't strictly require high precision for the desired response.
