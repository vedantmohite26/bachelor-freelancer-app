## 2026-02-21 - Cache Firestore Streams in State for Form Screens
**Learning:** `StreamBuilder` widgets inside form screens (such as `AddTransactionScreen`) will tear down and re-subscribe to stream getters if the streams are instantiated dynamically in `didChangeDependencies` without caching the user/entity ID. This causes unnecessary network/Firestore overhead and extra build frame churn on every keystroke.
**Action:** Cache stream instances in state using `_cachedUserId` checks in `didChangeDependencies` so `StreamBuilder` reuses existing stream objects across user input rebuilds.
