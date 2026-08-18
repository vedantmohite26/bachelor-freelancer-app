## 2026-08-18 - Single-Pass Distance Pre-calculation in Stream List Views
**Learning:** Calling heavy distance calculations like `Geolocator.distanceBetween` inside both stream filter predicates (`where`) and `ListView` item builders (`itemBuilder`) results in duplicate calculations during updates and repeated execution during list scrolling.
**Action:** Pre-calculate distances and formatted strings in a single pass over stream snapshot lists and cache the formatted string directly in job item maps (`_distanceDisplay`) before rendering.
