# 0001 — SCD type 2 with gaps and islands

**Context.** The source only publishes the current price of each station (and past days one by one). To answer "what did this station charge on 3 October?" the history has to be kept as versions with validity dates.

**Decision.** Keep one immutable bronze file per day. In silver, a new version starts when either price differs from the station's previous day (`lag`); a running `sum` of those starts numbers the versions ("gaps and islands"); each version gets `valid_from`, `valid_to` (the day before the next version) and `is_current`.

**Consequences.**
- The history can be rebuilt at any time from bronze, including a backfill of past days, without depending on when a snapshot job happened to run (a dbt snapshot would stamp versions with run time).
- Tests enforce the SCD2 rules: one current version per station, no overlaps or gaps between versions, one version per start date.
- 61 days of ~11,500 stations collapse into ~270,000 versions instead of ~700,000 daily rows.
