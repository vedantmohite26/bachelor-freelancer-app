## 2026-02-24 - [Initial Performance Audit]
**Learning:** Found multiple instances of `shrinkWrap: true` in `ListView.builder` paired with `SingleChildScrollView`, which disables virtualization. Also discovered `FutureBuilder` in `RatingSummaryCard` that triggers a new Firestore fetch on every rebuild because the future is not cached in a `StatefulWidget`.
**Action:** Prioritize replacing `shrinkWrap: true` with `CustomScrollView` + `SliverList` for virtualization, and convert `StatelessWidget`s with `FutureBuilder`s to `StatefulWidget`s to cache futures.
