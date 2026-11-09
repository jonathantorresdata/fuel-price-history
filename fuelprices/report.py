"""Static report (site/index.html) from the gold and silver tables."""

import json
from datetime import datetime, timezone
from pathlib import Path

import duckdb


def _rows(con, sql):
    cur = con.execute(sql)
    cols = [c[0] for c in cur.description]
    return [dict(zip(cols, r)) for r in cur.fetchall()]


def build_report(db_path: Path, out_dir: Path) -> Path:
    with duckdb.connect(str(db_path), read_only=True) as con:
        data = {
            "weekday": _rows(con, "SELECT day_name, diesel_vs_week_eur_per_1000l AS diesel, gasoline_95_vs_week_eur_per_1000l AS gasoline, days FROM gold.weekday_effect ORDER BY day_of_week"),
            "brands": _rows(con, "SELECT brand, stations, diesel FROM gold.brand_prices WHERE diesel IS NOT NULL ORDER BY diesel LIMIT 15"),
            "changes": _rows(con, "SELECT strftime(change_date, '%Y-%m-%d') AS day, pct_stations_changing AS pct, opened, closed FROM gold.daily_changes ORDER BY change_date"),
            "provinces": _rows(con, "SELECT province, diesel FROM gold.province_prices WHERE diesel IS NOT NULL ORDER BY diesel"),
            "scd": _rows(con, """SELECT count(*) AS versions, count(DISTINCT station_id) AS stations,
                                       round(avg(days_observed), 1) AS avg_days_same_price
                                FROM silver.price_history_scd2""")[0],
            "span": _rows(con, "SELECT strftime(min(price_date), '%Y-%m-%d') AS first, strftime(max(price_date), '%Y-%m-%d') AS last, count(DISTINCT price_date) AS days FROM silver.prices_daily")[0],
            "built_at": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
        }
    template = (Path(__file__).parent / "report_template.html").read_text()
    out_dir.mkdir(parents=True, exist_ok=True)
    page = out_dir / "index.html"
    page.write_text(template.replace("__DATA__", json.dumps(data, default=str)))
    return page
