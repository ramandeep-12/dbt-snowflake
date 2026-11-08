"""Create a small CSV of new bookings to test Snowpipe auto-ingest.

Usage (from the repo root):
    uv run python scripts/make_test_bookings.py
"""
from datetime import datetime
from pathlib import Path

import pandas as pd

now = datetime.now()
df = pd.read_csv("data/source/bookings.csv").head(5).copy()
df["booking_id"] = [f"NEW-{now:%Y%m%d%H%M%S}-{i}" for i in range(len(df))]
df["created_at"] = now.strftime("%Y-%m-%d %H:%M:%S")

out = Path("data/out") / f"bookings_{now:%Y%m%d_%H%M%S}.csv"
out.parent.mkdir(parents=True, exist_ok=True)
df.to_csv(out, index=False)
print(f"Wrote {len(df)} new bookings to {out}")