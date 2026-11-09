# 0003 — Detrend before comparing weekdays

**Context.** The first version compared each day with the average of its calendar week and found 95 petrol about 2.4 cents a litre dearer from Monday to Wednesday. But petrol fell 17.7 cents a litre over the period, so inside every week Monday was simply earlier in a falling market.

**Decision.** Compare each day with the centred 7-day moving average around it (3 days before and after), using only days with a full window.

**Consequences.**
- The weekday effect shrinks to about 1.4 cents a litre for petrol and almost nothing for diesel.
- The honest headline changes: the brand (about 21 cents a litre between cheapest and dearest for diesel) matters about 16 times more than the day.
