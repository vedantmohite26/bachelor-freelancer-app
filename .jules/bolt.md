# Bolt's Journal

## 2026-08-21 - Precomputing Distance Display in Scrollable Lists
**Learning:** In Flutter lists built with `ListView.separated` or `ListView.builder`, performing expensive calculations (like Haversine distance computations via `Geolocator.distanceBetween`) inside `itemBuilder` causes redundant calculations on every frame/re-render during scrolling.
**Action:** Consolidate distance calculations and string formatting into a single pass per stream/snapshot update, attaching formatted display strings directly to the data items before rendering.
