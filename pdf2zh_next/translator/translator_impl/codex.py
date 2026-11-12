import json
import logging
import subprocess
import tempfile
from pathlib import Path

from pdf2zh_next.config.model import SettingsModel
from pdf2zh_next.translator.base_rate_limiter import BaseRateLimiter
from pdf2zh_next.translator.base_translator import BaseTranslator

logger = logging.getLogger(__name__)


_BATCH_RESPONSE_SCHEMA = {
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "id": {"type": "integer"},
            "output": {"type": "string"},
        },
        "required": ["id", "output"],
        "additionalProperties": False,
    },
}
_TERM_RESPONSE_SCHEMA = {
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "src": {"type": "string"},
            "tgt": {"type": "string"},
        },
        "required": ["src", "tgt"],
        "additionalProperties": False,
    },
}


def _codex_response_schema(array_schema: dict) -> dict:
    """Codex CLI structured outputs require an object at the schema root."""
    return {
        "type": "object",
        "properties": {"items": array_schema},
        "required": ["items"],
        "additionalProperties": False,
    }


class CodexTranslator(BaseTranslator):
    """Use the locally authenticated Codex CLI as a BabelDOC translator."""

    name = "codex"
    skip_translation_health_check = True
    timeout_seconds = 300

    def __init__(
        self,
        settings: SettingsModel,
        rate_limiter: BaseRateLimiter,
    ):
        super().__init__(settings, rate_limiter)
        engine_settings = settings.translate_engine_settings
        self.codex_path = engine_settings.codex_path
        self.codex_model = engine_settings.codex_model
        self.add_cache_impact_parameters("model", self.codex_model or "codex-default")
        self.add_cache_impact_parameters("prompt", self.prompt(""))
        self._check_codex_cli()

    def _check_codex_cli(self):
        try:
            result = subprocess.run(
                [self.codex_path, "--version"],
                capture_output=True,
                text=True,
                timeout=10,
                check=False,
            )
        except FileNotFoundError as exc:
            raise ValueError(f"Codex CLI not found at '{self.codex_path}'") from exc
        except subprocess.TimeoutExpired as exc:
            raise ValueError("Codex CLI version check timed out") from exc
        if result.returncode != 0:
            detail = result.stderr.strip() or result.stdout.strip()
            raise ValueError(f"Codex CLI check failed: {detail}")

    def _run_codex(self, prompt: str, response_schema: dict | None = None) -> str:
        with tempfile.TemporaryDirectory(prefix="pdf2zh-codex-") as work_dir:
            output_path = Path(work_dir) / "response.txt"
            command = [
                self.codex_path,
                "exec",
                "--ephemeral",
                "--skip-git-repo-check",
                "--sandbox",
                "read-only",
                "--cd",
                work_dir,
            ]
            if self.codex_model:
                command.extend(["--model", self.codex_model])
            if response_schema is not None:
                schema_path = Path(work_dir) / "response-schema.json"
                schema_path.write_text(
                    json.dumps(response_schema, ensure_ascii=False), encoding="utf-8"
                )
                command.extend(["--output-schema", str(schema_path)])
            command.extend(["--output-last-message", str(output_path), "-"])

            logger.debug("Running Codex CLI translator with model %s", self.codex_model)
            try:
                result = subprocess.run(
                    command,
                    input=prompt,
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                    errors="replace",
                    timeout=self.timeout_seconds,
                    check=False,
                )
            except subprocess.TimeoutExpired as exc:
                raise TimeoutError(
                    f"Codex translation exceeded {self.timeout_seconds} seconds"
                ) from exc

            if result.returncode != 0:
                detail = result.stderr.strip() or result.stdout.strip()
                raise RuntimeError(f"Codex CLI failed ({result.returncode}): {detail}")
            if not output_path.is_file():
                raise RuntimeError("Codex CLI did not write its final response")
            response = output_path.read_text(encoding="utf-8").strip()
            if not response:
                raise RuntimeError("Codex CLI returned an empty response")
            return response

    def do_translate(self, text, rate_limit_params: dict = None) -> str:
        prompt = self.prompt(text)[0]["content"]
        return self._run_codex(prompt)

    def do_llm_translate(self, text, rate_limit_params: dict = None) -> str | None:
        # BabelDOC probes LLM support by calling this method with None. This
        # must be a local capability declaration, not an actual Codex turn.
        if text is None:
            return None
        schema = (
            _TERM_RESPONSE_SCHEMA
            if "### Extraction Rules" in text
            else _BATCH_RESPONSE_SCHEMA
        )
        codex_prompt = (
            f"{text}\n\n"
            'The required response schema wraps the requested JSON array in an '
            'object. Return exactly {"items": [ ... ]}; put the array you were '
            "asked to produce in the items field."
        )
        response = self._run_codex(codex_prompt, _codex_response_schema(schema))
        try:
            wrapped_response = json.loads(response)
            items = wrapped_response["items"]
            if not isinstance(items, list):
                raise TypeError("items must be an array")
        except (json.JSONDecodeError, KeyError, TypeError) as exc:
            raise ValueError("Codex returned an invalid wrapped JSON response") from exc
        return json.dumps(items, ensure_ascii=False)
