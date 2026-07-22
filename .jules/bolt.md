# Bolt's Journal

## 2026-10-24 - Firestore Stream Leak in WalletService
**Learning:** Calling `.snapshots().listen()` repeatedly on screen initialization or rebuilds creates multiple active, uncancelled Firestore stream subscriptions. This causes memory leaks and redundant database read operations.
**Action:** Store the stream subscription reference inside the service. Cancel any existing subscription before initiating a new one, and expose a cancel/dispose method to clean up references when services are destroyed or user sessions change.
