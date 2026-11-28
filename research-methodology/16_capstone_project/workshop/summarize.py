"""Summarize the fictional follow-up records in this workshop."""
import csv
from pathlib import Path

with Path(__file__).with_name("followup.csv").open(
    encoding="utf-8", newline=""
) as source:
    rows = list(csv.DictReader(source))

pending = {"due": "0", "completed": ""}
for row in rows:
    if row["due"] == pending["due"] and row["completed"] == pending["completed"]:
        continue
    if row["due"] != "1" or row["completed"] not in {"0", "1"}:
        raise ValueError(f"Invalid follow-up status for {row['case_id']}")

due = [row for row in rows if row["due"] == "1"]
completed = sum(row["completed"] == "1" for row in due)
rate = f"{completed / len(due):.1%}" if due else "undefined"
print(f"records={len(rows)} due={len(due)} completed={completed} rate={rate}")
