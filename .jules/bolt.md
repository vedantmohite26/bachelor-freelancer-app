## 2026-10-11 - JobFeedScreen Stream Caching & Distance Calculation Pass

**Learning:** `StreamBuilder` stream parameters evaluated directly inside `build()` trigger stream re-subscriptions on every rebuild. Additionally, evaluating trigonometric functions (like `Geolocator.distanceBetween`) per item inside scroll delegates causes repeated overhead.
**Action:** Cache stream instances in `didChangeDependencies()` and consolidate distance filtering and formatting into a single pass per stream snapshot update.
