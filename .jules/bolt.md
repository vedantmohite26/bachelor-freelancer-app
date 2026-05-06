## 2026-06-25 - Caching Futures in Stateless Widgets
**Learning:** In Flutter, using `FutureBuilder` with a future created directly in the `build` method (e.g., `userService.getUserProfile(id)`) causes a new future to be created on every build. This results in redundant network/database calls and unnecessary UI flickers.
**Action:** Convert the widget to a `StatefulWidget` and cache the future in `didChangeDependencies` (to access context-based services) and update it in `didUpdateWidget` only when the relevant ID changes.

## 2026-06-25 - Virtualization with CustomScrollView
**Learning:** The `SingleChildScrollView` + `Column` + `ListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` pattern disables `ListView` virtualization, forcing all items to be built and laid out at once (O(N)).
**Action:** Replace this pattern with `CustomScrollView` and `SliverList` (O(visible)) to ensure lazy loading of list items, especially important for screens with dynamic or large datasets like reviews or transaction histories. Use `SliverFillRemaining(hasScrollBody: false, child: ...)` for centered placeholders.
