"""Local live sync server for IGA Story Studio."""
from __future__ import annotations

import argparse
from datetime import datetime
from functools import partial
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import sys
import threading
import webbrowser

STUDIO_DIR = Path(__file__).resolve().parent
ROOT = STUDIO_DIR.parents[1]
if str(STUDIO_DIR) not in sys.path:
    sys.path.insert(0, str(STUDIO_DIR))

import sync_story  # noqa: E402


class StoryStudioHandler(SimpleHTTPRequestHandler):
    """Serve repo static assets plus JSON/Markdown/GDScript sync APIs."""

    def end_headers(self) -> None:
        if self.path.startswith("/api/") or self.path.startswith("/tools/story_studio/"):
            self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        super().end_headers()

    def log_message(self, format: str, *args: object) -> None:
        # Suppress noisy static asset logs; keep errors and API calls visible.
        if args and str(args[0]).startswith(("GET /api/", "POST /api/")):
            super().log_message(format, *args)

    def _send_json(self, payload: dict, status: int = HTTPStatus.OK) -> None:
        raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def _read_json_body(self) -> dict:
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0:
            return {}
        data = self.rfile.read(length)
        return json.loads(data.decode("utf-8"))

    def do_GET(self) -> None:
        if self.path in ["/", "/index.html"]:
            self.send_response(HTTPStatus.FOUND)
            self.send_header("Location", "/tools/story_studio/index.html")
            self.end_headers()
            return
        if self.path.startswith("/api/status"):
            self._send_json({
                "ok": True,
                "mode": "live_server",
                "root": str(ROOT),
                "bundle_exists": sync_story.BUNDLE_JSON.exists(),
            })
            return
        if self.path.startswith("/api/bundle"):
            if sync_story.BUNDLE_JSON.exists():
                bundle = json.loads(sync_story.BUNDLE_JSON.read_text(encoding="utf-8"))
            else:
                bundle = sync_story.build_bundle(preserve_existing=False)
                sync_story.export_web_data(bundle)
            self._send_json({"ok": True, "bundle": bundle})
            return
        super().do_GET()

    def do_POST(self) -> None:
        try:
            if self.path.startswith("/api/save"):
                payload = self._read_json_body()
                bundle = payload.get("bundle", payload)
                if not isinstance(bundle, dict) or "categories" not in bundle:
                    self._send_json({"ok": False, "error": "Invalid bundle payload"}, HTTPStatus.BAD_REQUEST)
                    return
                bundle["exported_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                sync_story.export_web_data(bundle)
                md_files = sync_story.export_markdown_scripts(bundle)
                self._send_json({
                    "ok": True,
                    "exported_at": bundle["exported_at"],
                    "markdown_files": [str(p.relative_to(ROOT)) for p in md_files],
                })
                return

            if self.path.startswith("/api/apply_game"):
                payload = self._read_json_body()
                bundle = payload.get("bundle", payload)
                if not isinstance(bundle, dict) or "categories" not in bundle:
                    self._send_json({"ok": False, "error": "Invalid bundle payload"}, HTTPStatus.BAD_REQUEST)
                    return
                bundle["exported_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                sync_story.export_web_data(bundle)
                md_files = sync_story.export_markdown_scripts(bundle)
                summary = sync_story.apply_bundle_to_gdscript(bundle)
                indent_errors = sync_story.verify_gd_indentation()
                if indent_errors:
                    self._send_json({"ok": False, "error": "Indentation verification failed", "details": indent_errors}, HTTPStatus.INTERNAL_SERVER_ERROR)
                    return
                self._send_json({
                    "ok": True,
                    "exported_at": bundle["exported_at"],
                    "markdown_files": [str(p.relative_to(ROOT)) for p in md_files],
                    **summary,
                })
                return

            if self.path.startswith("/api/reload_from_gd"):
                bundle = sync_story.build_bundle(preserve_existing=True)
                sync_story.export_web_data(bundle)
                sync_story.export_markdown_scripts(bundle)
                self._send_json({"ok": True, "bundle": bundle})
                return

            self._send_json({"ok": False, "error": "Unknown endpoint"}, HTTPStatus.NOT_FOUND)
        except Exception as exc:
            self._send_json({"ok": False, "error": str(exc)}, HTTPStatus.INTERNAL_SERVER_ERROR)


def create_server(port: int) -> tuple[ThreadingHTTPServer, int]:
    handler = partial(StoryStudioHandler, directory=str(ROOT))
    for candidate in range(port, port + 20):
        try:
            httpd = ThreadingHTTPServer(("127.0.0.1", candidate), handler)
            return httpd, candidate
        except OSError:
            continue
    raise OSError(f"No available port in range {port}-{port + 19}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--no-browser", action="store_true")
    args = parser.parse_args()

    # Ensure bundle exists on startup
    if not sync_story.BUNDLE_JSON.exists() or not sync_story.BUNDLE_JS.exists():
        bundle = sync_story.build_bundle(preserve_existing=True)
        sync_story.export_web_data(bundle)
        sync_story.export_markdown_scripts(bundle)

    httpd, bound_port = create_server(args.port)
    url = f"http://127.0.0.1:{bound_port}/tools/story_studio/index.html"
    print(f"IGA Story Studio running at {url}", flush=True)
    print("Press Ctrl+C to stop.", flush=True)

    if not args.no_browser:
        threading.Timer(0.4, lambda: webbrowser.open(url)).start()

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping IGA Story Studio server...")
    finally:
        httpd.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
