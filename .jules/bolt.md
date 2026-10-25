## 2026-05-18 - Stream instance caching in Flutter StatelessWidget to StatefulWidget conversion
**Learning:** Re-invoking stream factory getters (like `communityService.getPostsStream()`) directly inside `StreamBuilder` in a `StatelessWidget` causes Flutter to tear down and recreate stream controllers on every parent rebuild.
**Action:** Convert screens with top-level streams into `StatefulWidget` and cache the `Stream` instance in state during `didChangeDependencies()` or `initState()`.
