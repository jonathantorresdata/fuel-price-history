"""Extract daily fuel prices for every petrol station in Spain (Ministry for Ecological Transition).

One file per day in bronze: data/bronze/date=YYYY-MM-DD/prices.ndjson.gz, written atomically.
Past days are immutable and fetched once; today is refreshed on every run (prices change
during the day). The raw answer is ~12 MB per day, so only the fields the models use are kept.
"""

import gzip
import json
import logging
import time
import urllib.error
import urllib.request
from datetime import date, timedelta
from pathlib import Path

logger = logging.getLogger(__name__)

BASE = "https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes"
USER_AGENT = "fuel-price-history/1.0 (+https://github.com/jonathantorresdata/fuel-price-history)"
FIELDS = {
    "IDEESS": "station_id", "Rótulo": "brand", "Provincia": "province", "Municipio": "municipality",
    "C.P.": "postal_code", "Dirección": "address", "Latitud": "latitude", "Longitud (WGS84)": "longitude",
    "Precio Gasolina 95 E5": "price_gasoline_95", "Precio Gasoleo A": "price_diesel",
}


class FetchError(RuntimeError):
    pass


def url_for(day: date, today: date) -> str:
    return f"{BASE}/EstacionesTerrestres/" if day == today else f"{BASE}/EstacionesTerrestresHist/{day:%d-%m-%Y}"


def fetch(url: str, retries: int = 4) -> dict:
    request = urllib.request.Request(url, headers={"Accept": "application/json", "User-Agent": USER_AGENT})
    for attempt in range(1, retries + 1):
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                payload = json.loads(response.read().decode("utf-8-sig"))
            if payload.get("ResultadoConsulta") != "OK":
                raise FetchError(f"{url}: {payload.get('ResultadoConsulta')}")
            return payload
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as error:
            if attempt == retries:
                raise FetchError(f"{url} failed after {attempt} attempts: {error}") from error
            time.sleep(2 ** attempt)
    raise FetchError(url)


def slim(payload: dict, day: date) -> list[dict]:
    return [{"price_date": day.isoformat(), **{new: s.get(old) for old, new in FIELDS.items()}}
            for s in payload["ListaEESSPrecio"]]


def write_day(bronze_dir: Path, day: date, rows: list[dict]) -> Path:
    folder = bronze_dir / f"date={day.isoformat()}"
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / "prices.ndjson.gz"
    tmp = folder / "prices.tmp"
    with gzip.open(tmp, "wt", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    tmp.replace(path)
    return path


def days_to_fetch(bronze_dir: Path, start: date, today: date) -> list[date]:
    """Missing past days, plus today, which is always refreshed."""
    days, d = [], start
    while d <= today:
        if d == today or not (bronze_dir / f"date={d.isoformat()}" / "prices.ndjson.gz").exists():
            days.append(d)
        d += timedelta(days=1)
    return days


def extract(bronze_dir: Path, start: date, today: date) -> int:
    days = days_to_fetch(bronze_dir, start, today)
    for d in days:
        rows = slim(fetch(url_for(d, today)), d)
        write_day(bronze_dir, d, rows)
        logger.info("  %s  %6d stations", d, len(rows))
    return len(days)
