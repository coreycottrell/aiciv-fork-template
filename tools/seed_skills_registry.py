#!/usr/bin/env python3
"""
Skills Registry Seeder — provision-time population of memories/skills/registry.json
from the SKILL.md frontmatter on disk.

WHY THIS EXISTS
---------------
The constitution MANDATES a skills search before every task:
    grep -i "TASK_KEYWORD" ${CIV_ROOT}/memories/skills/registry.json
But a freshly-provisioned AiCIV ships registry.json as `{"skills": {}}` while
~140+ .claude/skills/*/SKILL.md files exist on disk. The mandated grep returns
NOTHING for every newborn — the discipline is dead-on-arrival.

This seeder reads every .claude/skills/*/SKILL.md, extracts a (name, description)
pair from each, and writes them into registry.json so the mandated grep returns
real, greppable entries from Day 1.

EXTRACTION RULES (robust to mixed formats on disk)
--------------------------------------------------
1. If the file has YAML frontmatter (--- ... ---):
     - name        := frontmatter `name:` if present, else the parent dir name
     - description := frontmatter `description:` if present (supports a single-line
                       value OR a YAML block/folded scalar continued on later lines),
                       else the first non-empty body line / H1 title
2. If the file has NO frontmatter:
     - name        := parent directory name
     - description := first H1 (`# Title`) or first non-empty content line
The parent-directory name is ALWAYS the canonical key (matches how skills are
referenced: `.claude/skills/<dir>/SKILL.md`), so name-collisions across the two
formats cannot happen.

This is a SEED, not a live tracker. It is idempotent: re-running regenerates the
registry from current disk state. Run it at provision time (and any time skills are
added in bulk). For per-injection usage analytics, see tools/skill_tracker.py
(a different concern — that logs when skills are LOADED, this catalogs what EXISTS).

USAGE
-----
    python3 tools/seed_skills_registry.py            # seed (writes registry.json)
    python3 tools/seed_skills_registry.py --check     # report counts, do not write
"""

import json
import os
import sys
from pathlib import Path

PROJECT_DIR = Path(os.environ.get("CLAUDE_PROJECT_DIR", str(Path(__file__).resolve().parent.parent)))
SKILLS_DIR = PROJECT_DIR / ".claude" / "skills"
REGISTRY_PATH = PROJECT_DIR / "memories" / "skills" / "registry.json"

MAX_DESC = 400  # cap description length to keep registry greppable and lean


def _first_content_line(lines):
    """First non-empty, non-divider line; strips leading H1 hashes."""
    for ln in lines:
        s = ln.strip()
        if not s or s == "---":
            continue
        return s.lstrip("#").strip()
    return ""


def parse_skill(skill_md: Path):
    """Return (name, description) for a SKILL.md. dir name is the canonical key."""
    dir_name = skill_md.parent.name
    try:
        text = skill_md.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return dir_name, ""
    lines = text.splitlines()

    name = dir_name
    description = ""

    # Detect YAML frontmatter: first non-blank line is '---'
    fm_start = None
    for i, ln in enumerate(lines):
        if ln.strip() == "":
            continue
        if ln.strip() == "---":
            fm_start = i
        break

    if fm_start is not None:
        # find closing '---'
        fm_end = None
        for j in range(fm_start + 1, len(lines)):
            if lines[j].strip() == "---":
                fm_end = j
                break
        if fm_end is not None:
            fm = lines[fm_start + 1:fm_end]
            for k, raw in enumerate(fm):
                stripped = raw.strip()
                if stripped.startswith("name:"):
                    val = stripped[len("name:"):].strip().strip('"').strip("'")
                    if val:
                        name = val
                elif stripped.startswith("description:"):
                    val = stripped[len("description:"):].strip()
                    # YAML block/folded scalar (| or >) — gather indented continuation
                    if val in ("|", ">", "|-", ">-", "|+", ">+"):
                        cont = []
                        for cont_ln in fm[k + 1:]:
                            if cont_ln.strip() == "" or cont_ln.startswith((" ", "\t")):
                                cont.append(cont_ln.strip())
                            else:
                                break
                        val = " ".join(c for c in cont if c)
                    else:
                        val = val.strip('"').strip("'")
                    description = val
            # frontmatter present but no description -> use first body line after fm
            if not description:
                description = _first_content_line(lines[fm_end + 1:])
        else:
            # malformed frontmatter; treat whole file as body
            description = _first_content_line(lines)
    else:
        # no frontmatter
        description = _first_content_line(lines)

    description = " ".join(description.split())  # collapse whitespace
    if len(description) > MAX_DESC:
        description = description[:MAX_DESC].rstrip() + "..."
    return name, description


def build_registry():
    skills = {}
    skill_files = sorted(SKILLS_DIR.glob("*/SKILL.md"))
    for sm in skill_files:
        key = sm.parent.name
        name, description = parse_skill(sm)
        skills[key] = {
            "name": name,
            "description": description,
            "path": f".claude/skills/{key}/SKILL.md",
        }
    return skills


def main():
    check_only = "--check" in sys.argv
    if not SKILLS_DIR.is_dir():
        print(f"ERROR: skills dir not found: {SKILLS_DIR}", file=sys.stderr)
        return 1

    skills = build_registry()
    registry = {
        "skills": skills,
        "notes": (
            "Auto-seeded from .claude/skills/*/SKILL.md frontmatter by "
            "tools/seed_skills_registry.py. Re-run to regenerate after adding skills. "
            "The mandated pre-task skills grep reads this file."
        ),
        "_meta": {"count": len(skills), "seeded_by": "tools/seed_skills_registry.py"},
    }

    print(f"Found {len(skills)} skills on disk under {SKILLS_DIR}")
    if check_only:
        print("--check: not writing.")
        return 0

    REGISTRY_PATH.parent.mkdir(parents=True, exist_ok=True)
    REGISTRY_PATH.write_text(json.dumps(registry, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {REGISTRY_PATH} ({len(skills)} skills).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
