## 2026-02-21 - Consolidate Distance Computations in Stream Builders
**Learning:** Performing trigonometric calculations like `Geolocator.distanceBetween` twice per item (once in `.where()` filter and once inside `ListView`'s `itemBuilder`) creates unnecessary CPU overhead on every scroll/re-render.
**Action:** Consolidate filtering and display string formatting into a single pass when stream snapshots arrive, caching calculated values directly on decorated item objects.
