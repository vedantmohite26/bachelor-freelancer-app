## 2026-03-30 - Single-pass list transformation for stream items with heavy calculations

**Learning:** Computing heavy trigonometric calculations (e.g., `Geolocator.distanceBetween` using Haversine formula) inside `ListView.builder` / `ListView.separated` delegates causes repetitive math operations on every scroll frame and UI rebuild. Moving distance calculation and string formatting into a single transformation pass on the raw stream snapshot eliminates trigonometric work during item builds.

**Action:** Whenever a list screen filters items or displays computed metrics (like distance, time elapsed, or formatted currency) derived from real-time snapshots or user position, compute and attach pre-calculated display strings during snapshot snapshot mapping rather than calculating inside item delegates.
