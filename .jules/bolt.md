# Bolt's Journal - Critical Learnings

## 2026-10-07 - StreamBuilder Stream Caching in StatefulWidget
**Learning:** Instantiating streams directly in `StreamBuilder.stream` inside a `StatelessWidget` causes stream listener teardowns and re-subscriptions on every widget rebuild (e.g. parent updates or orientation/theme changes).
**Action:** Convert screens with `StreamBuilder` to `StatefulWidget` and cache the stream instance in `didChangeDependencies()` to preserve stream subscriptions across rebuilds.
