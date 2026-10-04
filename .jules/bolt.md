
## 2026-10-04 - Caching Stream Instances in `CoinShopScreen` `didChangeDependencies`
**Learning:** Initializing Firestore streams inside `initState()` using `Provider.of<T>(context, listen: false)` is prone to using stale/unresolved provider instances or triggering unnecessary stream re-subscriptions if inherited widgets update. Initializing streams in `didChangeDependencies()` guarded by a boolean initialization flag safely binds to the correct inherited dependencies while preserving stream instances across parent widget rebuilds.
**Action:** Always move stream initializations from `initState()` or direct `StreamBuilder` creation into `didChangeDependencies()` with an `_isInitialized` guard flag in `StatefulWidget`s that depend on Provider context.
