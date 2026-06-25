## 2026-06-25 - [Leaderboard Virtualization]
**Learning:** The use of `shrinkWrap: true` in `ListView.builder` combined with `SingleChildScrollView` is a performance anti-pattern in Flutter. It forces the list to layout all items immediately, disabling virtualization and increasing memory and CPU usage as the list grows (O(N) layout).
**Action:** Replace `SingleChildScrollView` and nested `ListView.builder(shrinkWrap: true)` with a single `CustomScrollView` and `SliverList.builder` to enable virtualization (O(visible) layout).
