"""Guard (ticket 4090, INIT-058): the fork template must not pin a model version.
A newborn reads the SOTA model from ~/.claude_session_model / the platform default, never from a typed version here."""
import json, pathlib, re, unittest
ROOT = pathlib.Path(__file__).resolve().parent.parent
MODEL = re.compile(r"claude-(opus|sonnet|haiku)-\d")

class NoModelPins(unittest.TestCase):
    def test_settings_env_has_no_model_pin(self):
        env = json.loads((ROOT / ".claude/settings.json").read_text()).get("env", {})
        for k in ("ANTHROPIC_MODEL", "CLAUDE_CODE_SUBAGENT_MODEL"):
            self.assertNotIn(k, env)

    def test_launcher_names_no_model(self):
        for line in (ROOT / "tools/launch_civ_tower.sh").read_text().splitlines():
            if "claude --" in line and not line.lstrip().startswith("#"):
                self.assertNotIn("--model", line)
                self.assertIsNone(MODEL.search(line))

    def test_readiness_skill_no_launch_model(self):
        txt = (ROOT / ".claude/skills/fork-readiness-test/SKILL.md").read_text()
        self.assertNotRegex(txt, r"--model\s+claude-(sonnet|opus)")

if __name__ == "__main__":
    unittest.main()
