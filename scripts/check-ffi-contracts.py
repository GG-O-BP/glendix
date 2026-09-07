#!/usr/bin/env python3
"""Verify Glendix external exports and their documented dispositions."""

from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "FFI_BOUNDARIES.md"
SOURCE_DIRECTORIES = ("src", "dev", "test")
EXTERNAL = re.compile(
    r'@external\(\s*(javascript|erlang)\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)'
)
FUNCTION = re.compile(r"\bfn\s+([a-z][a-z0-9_]*)\s*\(")
JAVASCRIPT_EXPORT = re.compile(
    r"(?m)^\s*export\s+(?:async\s+)?function\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*\("
)
REFERENCE_ROW = re.compile(
    r"^\|\s*`(?P<declaration>[^`]+)`\s*"
    r"\|\s*`(?P<implementation>[^`]+)`\s*"
    r"\|\s*(?P<classification>Retained|Package adapter|Test only)\s*\|"
)


@dataclass(frozen=True)
class External:
    target: str
    module: str
    export: str
    function: str
    source: Path
    line: int

    @property
    def declaration_id(self) -> str:
        return f"{self.source.relative_to(ROOT).as_posix()}#{self.function}"

    @property
    def implementation(self) -> Path:
        return (self.source.parent / self.module).resolve()

    @property
    def implementation_id(self) -> str:
        path = self.implementation.relative_to(ROOT).as_posix()
        return f"{path}#{self.export}"


@dataclass(frozen=True)
class ReferenceEntry:
    declaration_id: str
    implementation_id: str
    classification: str
    line: int


def source_paths() -> list[Path]:
    paths: list[Path] = []
    for directory in SOURCE_DIRECTORIES:
        root = ROOT / directory
        if root.exists():
            paths.extend(sorted(root.rglob("*.gleam")))
    return paths


def externals_in(path: Path) -> list[External]:
    source = path.read_text()
    externals: list[External] = []
    for match in EXTERNAL.finditer(source):
        function_match = FUNCTION.search(source, match.end())
        if function_match is None:
            raise ValueError(f"{path}: external declaration has no function")
        externals.append(
            External(
                target=match.group(1),
                module=match.group(2),
                export=match.group(3),
                function=function_match.group(1),
                source=path,
                line=source.count("\n", 0, match.start()) + 1,
            )
        )
    return externals


def reference_entries() -> list[ReferenceEntry]:
    entries: list[ReferenceEntry] = []
    for line_number, line in enumerate(REFERENCE.read_text().splitlines(), start=1):
        match = REFERENCE_ROW.match(line)
        if match is None:
            continue
        entries.append(
            ReferenceEntry(
                declaration_id=match.group("declaration"),
                implementation_id=match.group("implementation"),
                classification=match.group("classification"),
                line=line_number,
            )
        )
    return entries


def check_javascript_export(
    external: External,
    cache: dict[Path, set[str]],
) -> list[str]:
    relative_source = external.source.relative_to(ROOT)
    implementation = external.implementation
    if not implementation.is_file():
        return [
            f"{relative_source}:{external.line}: missing JavaScript FFI file "
            f"{implementation.relative_to(ROOT)}"
        ]
    exports = cache.setdefault(
        implementation,
        set(JAVASCRIPT_EXPORT.findall(implementation.read_text())),
    )
    if external.export not in exports:
        return [
            f"{relative_source}:{external.line}: JavaScript FFI "
            f"{implementation.relative_to(ROOT)} does not export {external.export}"
        ]
    return []


def main() -> int:
    errors: list[str] = []
    externals: list[External] = []
    for path in source_paths():
        try:
            externals.extend(externals_in(path))
        except ValueError as error:
            errors.append(str(error))

    declaration_counts = Counter(external.declaration_id for external in externals)
    for declaration_id, count in sorted(declaration_counts.items()):
        if count > 1:
            errors.append(
                f"{declaration_id}: declaration identifier occurs {count} times"
            )

    javascript_cache: dict[Path, set[str]] = {}
    for external in externals:
        if external.target != "javascript":
            errors.append(
                f"{external.declaration_id}: unsupported documented target "
                f"{external.target}"
            )
            continue
        errors.extend(check_javascript_export(external, javascript_cache))

    if not REFERENCE.is_file():
        errors.append(f"missing FFI reference: {REFERENCE.relative_to(ROOT)}")
        entries: list[ReferenceEntry] = []
    else:
        entries = reference_entries()

    entry_counts = Counter(entry.declaration_id for entry in entries)
    for declaration_id, count in sorted(entry_counts.items()):
        if count > 1:
            errors.append(
                f"{REFERENCE.relative_to(ROOT)}: {declaration_id} is mapped "
                f"{count} times"
            )

    external_by_id = {
        external.declaration_id: external
        for external in externals
        if declaration_counts[external.declaration_id] == 1
    }
    entry_by_id = {
        entry.declaration_id: entry
        for entry in entries
        if entry_counts[entry.declaration_id] == 1
    }

    for declaration_id in sorted(external_by_id.keys() - entry_by_id.keys()):
        errors.append(f"{declaration_id}: external is missing from FFI_BOUNDARIES.md")
    for declaration_id in sorted(entry_by_id.keys() - external_by_id.keys()):
        entry = entry_by_id[declaration_id]
        errors.append(
            f"FFI_BOUNDARIES.md:{entry.line}: stale external mapping "
            f"{declaration_id}"
        )

    for declaration_id in sorted(external_by_id.keys() & entry_by_id.keys()):
        external = external_by_id[declaration_id]
        entry = entry_by_id[declaration_id]
        if entry.implementation_id != external.implementation_id:
            errors.append(
                f"FFI_BOUNDARIES.md:{entry.line}: {declaration_id} maps to "
                f"{entry.implementation_id}, expected {external.implementation_id}"
            )
        is_test = external.source.relative_to(ROOT).parts[0] == "test"
        if is_test and entry.classification != "Test only":
            errors.append(
                f"FFI_BOUNDARIES.md:{entry.line}: test external {declaration_id} "
                "must be classified as Test only"
            )
        if not is_test and entry.classification == "Test only":
            errors.append(
                f"FFI_BOUNDARIES.md:{entry.line}: production external "
                f"{declaration_id} cannot be classified as Test only"
            )

    if errors:
        print("FFI contract violations:")
        for error in errors:
            print("  " + error)
        return 1

    production_count = sum(
        external.source.relative_to(ROOT).parts[0] == "src"
        for external in externals
    )
    print(
        "FFI contracts passed for "
        f"{len(externals)} external declarations "
        f"({production_count} production, {len(externals) - production_count} test)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
