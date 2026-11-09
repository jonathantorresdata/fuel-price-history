# 0002 — Change data capture by comparing snapshots

**Context.** The source has no change feed: no "updated since" parameter and no deleted flag. Stations open and close, and about a third of them change a price every day.

**Decision.** Derive the changes: a full outer join between each day and the previous published day classifies every station as `insert` (new), `delete` (gone) or `update` (a price changed).

**Consequences.**
- Daily counts of openings, closures and price changes, and the share of stations that move prices.
- A reconciliation test proves the logic: today's stations = yesterday's + inserts − deletes, for every day.
