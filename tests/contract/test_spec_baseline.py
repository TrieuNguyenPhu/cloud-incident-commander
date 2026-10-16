import csv
import hashlib
import re
from graphlib import TopologicalSorter
from pathlib import Path

DOCS = Path(__file__).resolve().parents[2] / "docs"


def test_current_specification_matches_manifest():
    for line in (DOCS / "MANIFEST_SHA256.txt").read_text(encoding="utf-8").splitlines():
        digest, name = line.split("  ", 1)
        assert hashlib.sha256((DOCS / name).read_bytes()).hexdigest() == digest, name


def test_backlog_dependencies_and_audit_coverage():
    with (DOCS / "05_BACKLOG_IMPORT.csv").open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    assert len(rows) == 72
    graph = {row["Issue ID"]: set(filter(None, row["Depends On"].split(","))) for row in rows}
    assert len(graph) == 72
    assert all(
        dependency in graph for dependencies in graph.values() for dependency in dependencies
    )
    assert len(tuple(TopologicalSorter(graph).static_order())) == 72
    audit = (DOCS / "19_AUDIT_RESOLUTION.md").read_text(encoding="utf-8")
    assert len(re.findall(r"^\| [BHM]\d{2} \|", audit, re.M)) == 23
    trace = (DOCS / "08_REQUIREMENT_TRACEABILITY.md").read_text(encoding="utf-8")
    assert len(set(re.findall(r"FR-\d{3}", trace))) == 28
    assert len(set(re.findall(r"NFR-\d{3}", trace))) == 14
