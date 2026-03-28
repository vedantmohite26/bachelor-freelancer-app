## 2025-05-15 - Redundant Distance Calculation in Job Feed
**Learning:** Calculating distances using `Geolocator.distanceBetween` is an expensive operation. Performing this calculation in both the filtering logic and the `itemBuilder` of a `ListView` (which can be called frequently during scroll or rebuild) creates a significant performance bottleneck and causes UI jank.
**Action:** Consolidate distance calculations by processing the data once (e.g., within a `StreamBuilder` or `FutureBuilder`) and storing the results (both numeric for sorting/filtering and formatted strings for display) within the data object itself. This ensures $O(N)$ calculation once per data update rather than $O(N)$ on every frame/scroll.

## 2025-05-15 - Handling Truncated File Reads in Tool Outputs
**Learning:** Large files like `job_feed_screen.dart` (>12k characters) can be truncated by the environment's tool output limits, leading to incomplete code visibility and incorrect planning.
**Action:** Use `sed -n 'START,ENDp'` with small, manageable line ranges (e.g., 50-100 lines) to read through large files in chunks when `read_file` or `cat` output is truncated. Always verify that the entire relevant logic (like a full `build` method) has been observed before proposing a refactor.
