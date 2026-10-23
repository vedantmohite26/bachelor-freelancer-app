## 2026-10-23 - State Stream Caching and didUpdateWidget Lifecycle in Flutter Profile Screens

**Learning:** Re-instantiating Firestore streams inside `build()` methods in `StatelessWidget` screen components causes continuous tear-down and re-subscription overhead whenever parent widgets trigger rebuilds. Moving stream creation into `StatefulWidget` state (`didChangeDependencies()`) prevents stream recreation. Crucially, for screens with dynamic parameter props like `helperId`, implementing `didUpdateWidget()` to invalidate and recreate stream instances when the property changes is required to avoid displaying stale stream data.

**Action:** When converting stream-consuming screens or cards to `StatefulWidget`s for stream caching, always implement both `didChangeDependencies()` (for provider context dependencies) and `didUpdateWidget()` (for dynamic widget constructor properties).
