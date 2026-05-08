# Bolt ⚡ Performance Journal

## 2026-06-15 - [Anti-pattern] Nested Scroll with `shrinkWrap: true`
**Learning:** Using `ListView(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` inside a `SingleChildScrollView` is a common performance anti-pattern in Flutter. It forces the `ListView` to calculate the height of all its children at once, effectively disabling virtualization and causing O(N) build/layout time.
**Action:** Replace with `CustomScrollView` and `SliverList` to enable virtualization, reducing rendering complexity to O(visible).

## 2026-06-15 - [Optimization] `FutureBuilder` Future Caching
**Learning:** Passing a method call that returns a new `Future` directly to `FutureBuilder.future` in a `StatelessWidget` causes the operation (e.g., Firestore fetch) to trigger on every rebuild of the parent or the widget itself.
**Action:** Convert to `StatefulWidget` and cache the `Future` in a state variable, initializing it in `initState` or `didChangeDependencies`.

## 2026-06-15 - [Pattern] `StreamBuilder` with `CustomScrollView`
**Learning:** When using `StreamBuilder` to provide data for a `CustomScrollView`, the builder must return a widget that is compatible with the parent's layout expectations. If it's the `body` of a `Scaffold`, it should return the `CustomScrollView` itself, and handle loading/empty states using `SliverFillRemaining` to maintain a consistent UI within the sliver-based coordinate system.
**Action:** Wrap `CustomScrollView` with `StreamBuilder` and use `SliverFillRemaining(hasScrollBody: false, child: ...)` for non-sliver placeholder widgets like `CircularProgressIndicator`.
