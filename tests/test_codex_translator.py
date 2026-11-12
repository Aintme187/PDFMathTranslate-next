import json
import subprocess
import unittest
from pathlib import Path
from unittest.mock import patch

from pdf2zh_next.config.model import SettingsModel
from pdf2zh_next.config.translate_engine_model import CodexSettings
from pdf2zh_next.translator.rate_limiter.qps_rate_limiter import QPSRateLimiter
from pdf2zh_next.translator.translator_impl.codex import CodexTranslator
from pdf2zh_next.translator.utils import _create_translator_instance


class CodexTranslatorTests(unittest.TestCase):
    def setUp(self):
        self.settings = SettingsModel(
            translate_engine_settings=CodexSettings(),
        )
        self.rate_limiter = QPSRateLimiter(1000)

    def _fake_codex_run(self, command, **_kwargs):
        if command[1:] == ["--version"]:
            return subprocess.CompletedProcess(command, 0, "codex-cli", "")

        output_path = Path(command[command.index("--output-last-message") + 1])
        schema_path = command[command.index("--output-schema") + 1]
        schema = json.loads(Path(schema_path).read_text(encoding="utf-8"))
        self.assertEqual(schema["type"], "object")
        self.assertIn("items", schema["properties"])
        output_path.write_text(
            '{"items":[{"id":0,"output":"对称张量"}]}', encoding="utf-8"
        )
        return subprocess.CompletedProcess(command, 0, "", "")

    def test_batch_response_is_unwrapped_for_babeldoc(self):
        with patch(
            "pdf2zh_next.translator.translator_impl.codex.subprocess.run",
            side_effect=self._fake_codex_run,
        ):
            translator = CodexTranslator(self.settings, self.rate_limiter)
            response = translator.do_llm_translate(
                '[{"id":0,"input":"symmetric tensor"}]'
            )

        self.assertEqual(json.loads(response), [{"id": 0, "output": "对称张量"}])

    def test_term_response_uses_term_schema_and_is_unwrapped(self):
        def fake_term_run(command, **_kwargs):
            if command[1:] == ["--version"]:
                return subprocess.CompletedProcess(command, 0, "codex-cli", "")
            output_path = Path(command[command.index("--output-last-message") + 1])
            schema_path = command[command.index("--output-schema") + 1]
            schema = json.loads(Path(schema_path).read_text(encoding="utf-8"))
            item_schema = schema["properties"]["items"]["items"]
            self.assertEqual(set(item_schema["properties"]), {"src", "tgt"})
            output_path.write_text(
                '{"items":[{"src":"tensor","tgt":"张量"}]}',
                encoding="utf-8",
            )
            return subprocess.CompletedProcess(command, 0, "", "")

        with patch(
            "pdf2zh_next.translator.translator_impl.codex.subprocess.run",
            side_effect=fake_term_run,
        ):
            translator = CodexTranslator(self.settings, self.rate_limiter)
            response = translator.do_llm_translate("### Extraction Rules\nExtract terms")

        self.assertEqual(json.loads(response), [{"src": "tensor", "tgt": "张量"}])

    def test_codex_config_registration_skips_hello_health_translation(self):
        commands = []

        def fake_run(command, **_kwargs):
            commands.append(command)
            return subprocess.CompletedProcess(command, 0, "codex-cli", "")

        with patch(
            "pdf2zh_next.translator.translator_impl.codex.subprocess.run",
            side_effect=fake_run,
        ):
            translator, _, _ = _create_translator_instance(
                settings=self.settings,
                translator_config=self.settings.translate_engine_settings,
                rate_limiter=self.rate_limiter,
            )

        self.assertIsInstance(translator, CodexTranslator)
        self.assertEqual(commands, [["codex", "--version"]])
