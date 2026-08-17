## 2026-11-15 - Consolidate Location Calculations in Scroll Builders
**Learning:** Performing trigonometric operations (`Geolocator.distanceBetween`) directly inside a `ListView` item builder causes CPU spikes and scrolling stutter because distance is re-calculated for every visible item during scrolling.
**Action:** Always pre-calculate and cache distance strings on the list items in a single pass when stream data updates before passing the items to `ListView.builder`.
