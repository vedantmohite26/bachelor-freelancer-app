# Bolt's Performance Journal - Earnify

## 2026-06-25 - Initial Performance Audit
**Learning:** Found multiple instances of the `shrinkWrap: true` anti-pattern in Flutter lists (Wallet, Leaderboard, Safety Center, Helper Reviews). This pattern disables virtualization and causes O(N) build time for lists, which is a significant bottleneck as data grows.
**Action:** Prioritize replacing `SingleChildScrollView` + `shrinkWrap: true` with `CustomScrollView` + `SliverList` for virtualization.

## 2026-06-25 - Stream Management in UI
**Learning:** Initializing streams directly in `StreamBuilder.stream` or `build()` methods causes redundant subscriptions and Firestore reads on every rebuild.
**Action:** Cache streams in `StatefulWidget`'s `initState` and handle updates in `didUpdateWidget`.
