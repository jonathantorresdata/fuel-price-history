"""Extract → dbt build (models + tests) → report. Exit code 1 on any failure.

Usage:
    python scripts/run_pipeline.py              # incremental: missing days + today
    python scripts/run_pipeline.py --days 90    # keep (and backfill) the last 90 days
    python scripts/run_pipeline.py --skip-extract
"""

import argparse
import logging
import subprocess
import sys
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from fuelprices.extract import FetchError, extract  # noqa: E402
from fuelprices.report import build_report  # noqa: E402

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
logger = logging.getLogger("pipeline")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--days", type=int, default=60)
    parser.add_argument("--skip-extract", action="store_true")
    args = parser.parse_args()

    if not args.skip_extract:
        logger.info("1/3 Extract")
        try:
            extract(ROOT / "data" / "bronze", date.today() - timedelta(days=args.days), date.today())
        except FetchError as error:
            logger.error(error)
            return 1
    logger.info("2/3 dbt build")
    dbt = ROOT / "dbt"
    if subprocess.run(["dbt", "build", "--project-dir", str(dbt), "--profiles-dir", str(dbt)], cwd=dbt).returncode:
        logger.error("dbt build failed")
        return 1
    logger.info("3/3 Report")
    logger.info("Done: %s", build_report(ROOT / "data" / "fuelprices.duckdb", ROOT / "site"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
