## 2026-03-31 - Cache Streams and Profile Futures in Chat List Items
**Learning:** Instantiating streams in `ChatListScreen.build()` or calling async profile fetch futures inside `_ChatListItem.build()` causes redundant Firestore subscriptions and repeated database reads on every scroll or rebuild event.
**Action:** Convert list components and item widgets to `StatefulWidget` to cache stream subscriptions and profile futures in state, and wrap list items in `RepaintBoundary`.
