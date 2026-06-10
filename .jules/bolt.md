## 2026-06-25 - [Virtualizing decorated lists in Flutter]
**Learning:** In Flutter, to apply a `BoxDecoration` to a virtualized list within a `CustomScrollView`, `DecoratedSliver` is the correct choice. Wrapping a `SliverList` in a standard `Container` or `DecoratedBox` won't work as they are not slivers.
**Action:** Use `DecoratedSliver` (available since Flutter 3.10) to maintain UI consistency (e.g. background colors, rounded corners) while replacing the `shrinkWrap: true` anti-pattern with efficient virtualization.
