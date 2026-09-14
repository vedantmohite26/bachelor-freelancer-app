## 2026-11-20 - Repaint boundary isolation in real-time feed items
**Learning:** Wrapping dynamically updated items (e.g., `_PostCard` in `CampusFeedScreen`) rendered within a `ListView.separated` inside a `RepaintBoundary` prevents paint invalidation from propagating across adjacent items when real-time snapshot events update likes or comments.
**Action:** When working with real-time stream-driven lists in Flutter, wrap individual card widgets in a `RepaintBoundary` to isolate repaints and maintain 60 FPS scrolling.
