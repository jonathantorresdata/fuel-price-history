import gzip
import json
from datetime import date

from fuelprices.extract import days_to_fetch, slim, url_for, write_day


def test_today_uses_the_live_endpoint_and_past_days_the_history():
    today = date(2026, 11, 9)
    assert url_for(today, today).endswith("/EstacionesTerrestres/")
    assert url_for(date(2026, 11, 1), today).endswith("/EstacionesTerrestresHist/01-11-2026")


def test_past_days_are_fetched_once_and_today_always(tmp_path):
    write_day(tmp_path, date(2026, 11, 7), [])
    write_day(tmp_path, date(2026, 11, 9), [])
    days = days_to_fetch(tmp_path, date(2026, 11, 7), date(2026, 11, 9))
    assert days == [date(2026, 11, 8), date(2026, 11, 9)]


def test_slim_keeps_only_the_needed_fields():
    payload = {"ListaEESSPrecio": [{"IDEESS": "1", "Rótulo": "REPSOL", "Precio Gasoleo A": "1,459", "Horario": "24H"}]}
    row = slim(payload, date(2026, 11, 9))[0]
    assert row["station_id"] == "1" and row["brand"] == "REPSOL" and row["price_diesel"] == "1,459"
    assert "Horario" not in row and row["price_date"] == "2026-11-09"


def test_write_day_is_gzip_ndjson_and_atomic(tmp_path):
    path = write_day(tmp_path, date(2026, 11, 9), [{"a": 1}, {"a": 2}])
    with gzip.open(path, "rt") as f:
        assert [json.loads(line) for line in f] == [{"a": 1}, {"a": 2}]
    assert not list(tmp_path.rglob("*.tmp"))
