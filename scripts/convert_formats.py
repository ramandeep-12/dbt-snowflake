"""Create a nested JSON copy of listings and a Parquet copy of hosts.

Usage (from the repo root):
    uv run python scripts/convert_formats.py data/source data/out
"""
import json
import sys
from pathlib import Path

import pandas as pd


def convert_listings(src: Path, out: Path) -> None:
    """Write listings as a JSON array, with city and country nested under address."""
    df = pd.read_csv(src / "listings.csv")
    df = df.astype(object).where(df.notna(), None)  # NaN -> null (valid JSON)
    records = []
    for row in df.to_dict(orient="records"):
        row["address"] = {"city": row.pop("city"), "country": row.pop("country")}
        records.append(row)
    (out / "listings.json").write_text(json.dumps(records, indent=2, default=str))
    print(f"listings.json: {len(records)} records")


def convert_hosts(src: Path, out: Path) -> None:
    """Write hosts as Parquet with real date, timestamp and boolean types."""
    df = pd.read_csv(src / "hosts.csv")
    df["host_since"] = pd.to_datetime(df["host_since"]).dt.date
    df["created_at"] = pd.to_datetime(df["created_at"])
    df.to_parquet(
        out / "hosts.parquet",
        index=False,
        coerce_timestamps="ms",
        allow_truncated_timestamps=True,
    )
    print(f"hosts.parquet: {len(df)} rows")


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit("Usage: convert_formats.py <source_dir> <output_dir>")
    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    convert_listings(src, out)
    convert_hosts(src, out)


if __name__ == "__main__":
    main()