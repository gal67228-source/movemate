#!/usr/bin/env python3
"""Publish MoveMate changes to GitHub and wait for GitHub Actions when possible."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import webbrowser


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW_FILE = "flutter-ci.yml"


class PublishError(RuntimeError):
    pass


def run(
    command: list[str],
    *,
    check: bool = True,
    capture: bool = False,
    cwd: Path = ROOT,
) -> subprocess.CompletedProcess[str]:
    print("\n$ " + " ".join(command), flush=True)
    result = subprocess.run(
        command,
        cwd=cwd,
        check=False,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )
    if check and result.returncode != 0:
        details = ""
        if capture:
            details = f"\n{result.stdout or ''}{result.stderr or ''}".rstrip()
        raise PublishError(
            f"Command failed with exit code {result.returncode}: {' '.join(command)}{details}"
        )
    return result


def output(command: list[str]) -> str:
    return run(command, capture=True).stdout.strip()


def require_tool(name: str, install_hint: str) -> None:
    if shutil.which(name) is None:
        raise PublishError(f"Missing required tool: {name}. {install_hint}")


def ensure_git_repository() -> None:
    if not (ROOT / ".git").exists():
        raise PublishError(
            "This folder is not a Git repository. Run git init and configure the "
            "GitHub remote before publishing."
        )


def get_branch() -> str:
    branch = output(["git", "branch", "--show-current"])
    if not branch:
        raise PublishError("Git is in detached HEAD state. Check out a branch first.")
    return branch


def get_remote_url() -> str:
    result = run(["git", "remote", "get-url", "origin"], check=False, capture=True)
    if result.returncode != 0 or not result.stdout.strip():
        raise PublishError(
            "Remote 'origin' is not configured. Add it with: "
            "git remote add origin https://github.com/USERNAME/movemate.git"
        )
    return result.stdout.strip()


def run_local_checks(skip_build: bool) -> None:
    require_tool("flutter", "Install Flutter stable and add it to PATH.")
    require_tool("dart", "Dart is included with Flutter; add Flutter's bin folder to PATH.")

    print("\nRunning local quality checks...", flush=True)
    run(["flutter", "pub", "get"])
    run(["dart", "format", "lib", "test"])
    run(["flutter", "analyze", "--fatal-infos"])
    run(["flutter", "test", "--reporter=expanded"])
    if not skip_build:
        run(["flutter", "build", "apk", "--debug"])


def has_worktree_changes() -> bool:
    return bool(output(["git", "status", "--porcelain"]))


def commit_changes(message: str) -> bool:
    if not has_worktree_changes():
        print("\nNo uncommitted changes were found. The current branch will still be pushed.")
        return False

    run(["git", "add", "--all"])
    staged = run(["git", "diff", "--cached", "--quiet"], check=False)
    if staged.returncode == 0:
        print("\nNothing changed after formatting; no commit was created.")
        return False
    if staged.returncode != 1:
        raise PublishError("Could not inspect staged Git changes.")

    run(["git", "commit", "-m", message])
    return True


def push(branch: str) -> str:
    run(["git", "push", "--set-upstream", "origin", branch])
    return output(["git", "rev-parse", "HEAD"])


def github_repository_url(remote_url: str) -> str | None:
    url = remote_url.strip()
    if url.startswith("git@github.com:"):
        url = "https://github.com/" + url.removeprefix("git@github.com:")
    elif url.startswith("ssh://git@github.com/"):
        url = "https://github.com/" + url.removeprefix("ssh://git@github.com/")
    elif url.startswith("https://github.com/"):
        pass
    else:
        return None
    return url.removesuffix(".git")


def find_run_for_commit(branch: str, sha: str, timeout_seconds: int = 90) -> tuple[int, str] | None:
    if shutil.which("gh") is None:
        return None

    print("\nWaiting for GitHub Actions to register the pushed commit...", flush=True)
    deadline = time.monotonic() + timeout_seconds
    while time.monotonic() < deadline:
        result = run(
            [
                "gh",
                "run",
                "list",
                "--workflow",
                WORKFLOW_FILE,
                "--branch",
                branch,
                "--limit",
                "10",
                "--json",
                "databaseId,headSha,url,status,conclusion",
            ],
            check=False,
            capture=True,
        )
        if result.returncode == 0:
            try:
                runs = json.loads(result.stdout or "[]")
            except json.JSONDecodeError:
                runs = []
            for item in runs:
                if item.get("headSha") == sha:
                    return int(item["databaseId"]), str(item.get("url", ""))
        time.sleep(3)
    return None


def watch_ci(branch: str, sha: str, remote_url: str, open_browser: bool) -> None:
    repo_url = github_repository_url(remote_url)
    actions_url = f"{repo_url}/actions" if repo_url else None

    if shutil.which("gh") is None:
        print(
            "\nPush completed. GitHub Actions was triggered automatically. "
            "Install and authenticate GitHub CLI ('gh auth login') to let this tool "
            "wait for the CI result."
        )
        if actions_url:
            print(f"Actions: {actions_url}")
            if open_browser:
                webbrowser.open(actions_url)
        return

    found = find_run_for_commit(branch, sha)
    if found is None:
        print("\nThe push succeeded, but the matching CI run was not found yet.")
        if actions_url:
            print(f"Actions: {actions_url}")
            if open_browser:
                webbrowser.open(actions_url)
        return

    run_id, run_url = found
    if run_url:
        print(f"\nCI run: {run_url}")
        if open_browser:
            webbrowser.open(run_url)
    print("Waiting for CI to finish...", flush=True)
    result = run(["gh", "run", "watch", str(run_id), "--exit-status"], check=False)
    if result.returncode != 0:
        raise PublishError(f"GitHub Actions failed. Open the run for details: {run_url}")
    print("\nGitHub Actions completed successfully. The APK artifact is ready.")


def parse_args() -> argparse.Namespace:
    default_message = "Update MoveMate " + dt.datetime.now().astimezone().strftime(
        "%Y-%m-%d %H:%M"
    )
    parser = argparse.ArgumentParser(
        description="Run checks, commit changes, push to GitHub, and watch Flutter CI."
    )
    parser.add_argument(
        "message",
        nargs="?",
        default=default_message,
        help="Git commit message.",
    )
    parser.add_argument(
        "--skip-checks",
        action="store_true",
        help="Skip local Flutter analysis and tests.",
    )
    parser.add_argument(
        "--skip-local-build",
        action="store_true",
        help="Run analysis and tests but skip the local debug APK build.",
    )
    parser.add_argument(
        "--no-wait",
        action="store_true",
        help="Push without waiting for GitHub Actions.",
    )
    parser.add_argument(
        "--open",
        action="store_true",
        dest="open_browser",
        help="Open the GitHub Actions page in the default browser.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        os.chdir(ROOT)
        require_tool("git", "Install Git and add it to PATH.")
        ensure_git_repository()
        branch = get_branch()
        remote_url = get_remote_url()

        print(f"MoveMate repository: {ROOT}")
        print(f"Branch: {branch}")
        print(f"Remote: {remote_url}")

        if not args.skip_checks:
            run_local_checks(skip_build=args.skip_local_build)
        else:
            print("\nLocal checks were skipped by request.")

        commit_changes(args.message)
        sha = push(branch)
        print(f"\nPushed commit: {sha[:12]}")

        if not args.no_wait:
            watch_ci(branch, sha, remote_url, args.open_browser)
        else:
            print("GitHub Actions was triggered by the push; CI waiting was skipped.")
        return 0
    except PublishError as error:
        print(f"\nERROR: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("\nCancelled.", file=sys.stderr)
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
