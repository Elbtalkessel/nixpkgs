#!/usr/bin/env python

import argparse
import os
import re
import shlex
import socket
import typing
from pathlib import Path
from subprocess import PIPE, Popen, TimeoutExpired

RE_URL = re.compile(
    r"((?P<proto>git@|https://)(?P<host>[\w\.@]+)(/|:))(?P<owner>[\w,\-,\_]+)/(?P<repo>[.\w,\-,\_]+)(.git){1}((/){0,1})"
)


class Result(typing.NamedTuple):
    out: str
    err: str
    code: int


class Process:
    args: tuple[str, ...]

    def __init__(self, *args: str, timeout=15):
        self.args = args if len(args) > 1 else tuple(shlex.split(args[0]))
        self.timeout = timeout

    def run(self) -> Result:
        process = Popen(self.args, stdout=PIPE, stderr=PIPE)
        try:
            stdout, stderr = process.communicate(timeout=self.timeout)
        except TimeoutExpired:
            process.kill()
            stdout, stderr = process.communicate()
        return Result(
            out=stdout.decode().strip(),
            err=stderr.decode().strip(),
            code=process.returncode,
        )

    def try_run(self) -> str:
        r = self.run()
        if r.code != 0:
            raise RuntimeError(r.err)
        return r.out


class Git:
    proto: typing.Literal["git", "https"]
    host: str
    owner: str
    repo: str
    origin: str

    def __init__(self, url: str) -> None:
        m = RE_URL.search(url)
        assert m is not None, "invalid git url, git@.. or https:// only."
        self.proto = "git" if "git" in m.group("proto") else "https"
        self.host = m.group("host")
        self.owner = m.group("owner")
        self.repo = m.group("repo")
        self.origin = url

    @property
    def wiki(self) -> "Git":
        return Git(url=self.origin.replace(".git", ".wiki.git"))

    def clone(self, path: Path) -> str:
        return Process("git", "clone", self.origin, str(path), timeout=60).try_run()

    def pull(self, path: Path) -> str:
        if not path.exists():
            raise ValueError(f"path {path} does not exist.")
        if not (path / ".git").exists():
            raise ValueError(f"path {path} is not git managed.")
        return Process("git", "-C", str(path), "pull", "--rebase").try_run()

    def ensure(self, path: Path) -> str:
        if path.exists() and (path / ".git").exists():
            return self.pull(path)
        return self.clone(path)

    @classmethod
    def from_path(cls, path: Path) -> "Git":
        result = Process(
            "git", "-C", str(path), "remote", "get-url", "origin"
        ).try_run()
        return cls(result)

    def worktree_add(
        self, reference_path: Path, worktrees_path: Path, branch: str
    ) -> Path:
        path = worktrees_path / branch
        Process(
            "git", "-C", str(reference_path), "worktree", "add", str(path), "-b", branch
        ).try_run()
        return path

    def worktree_remove(
        self, reference_path: Path, worktrees_path: Path, branch: str
    ) -> None:
        path = worktrees_path / branch
        r = Process(
            "git", "-C", str(reference_path), "worktree", "remove", str(path)
        ).run()
        if r.code != 0:
            print(r.err)
        r = Process("git", "-C", str(reference_path), "branch", "-D", branch).run()
        if r.code != 0:
            print(r.err)


class Manager:
    root: Path
    _worktrees: Path
    _wikis: Path
    git: Git

    def __init__(self, root: Path, url: str):
        self.root = root
        self._worktrees = self.root / "worktrees"
        self._wikis = self.root / "wikis"
        self.git = (
            Git(url) if url.startswith(("git", "http")) else Git.from_path(root / url)
        )

        self.root.mkdir(exist_ok=True)
        self._worktrees.mkdir(exist_ok=True)
        self._wikis.mkdir(exist_ok=True)

    @property
    def project(self) -> Path:
        return self.root / self.git.owner / self.git.repo

    @property
    def wiki(self) -> Path:
        return self._wikis / self.git.owner / self.git.repo

    @property
    def wiki_all(self) -> Path:
        return self.wiki / "ALL.md"

    @property
    def wiki_source(self) -> Path:
        return self.wiki / "source"

    @property
    def worktrees(self) -> Path:
        return self._worktrees / self.git.owner / self.git.repo

    def setup(self) -> Path:
        self.project.mkdir(parents=True, exist_ok=True)
        if not (self.project / ".git").exists():
            self.git.clone(self.project)
        else:
            self.git.pull(self.project)
        return self.project

    def wiki_sync(self) -> Path:
        self.wiki_source.mkdir(parents=True, exist_ok=True)
        self.git.wiki.ensure(self.wiki_source)
        return self.wiki_source

    def info(self):
        items = (
            ("Username", Process("git config --get user.name").try_run()),
            ("Email", Process("git config --get user.email").try_run()),
            ("Hostname", socket.gethostname()),
            ("Wiki", str(self.wiki_all)),
            ("Project", str(self.project)),
            ("Worktrees", str(self.worktrees)),
            ("Wiki Git", self.git.wiki.origin),
            ("Project Git", self.git.origin),
        )
        for name, value in items:
            print(f"{name}: {value}")

    def worktree_add(self, branch: str) -> Path:
        return self.git.worktree_add(self.project, self.worktrees, branch)

    def worktree_remove(self, branch: str) -> None:
        self.git.worktree_remove(self.project, self.worktrees, branch)


def combine_wiki(managers: list[Manager], output: Path):
    if output.exists():
        output.unlink()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.touch()
    with open(output, "at") as f:
        for manager in managers:
            result = manager.wiki_sync()
            for page in result.glob("*.md"):
                f.write("----\n")
                f.write(f"source: {page.name} from {manager.git.wiki.origin}\n")
                f.write(page.read_text())


def parse_args(root: Path) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-u",
        "--url",
        help="full url (required for running setup) or only <owner>/<repo>",
        type=str,
        metavar="REPOSITORY_URL",
        required=True,
    )
    parser.add_argument(
        "-s",
        "--setup",
        help="setup repository, requires full url",
        action="store_true",
        default=False,
    )
    parser.add_argument(
        "-w",
        "--wiki",
        help="sync and merge wiki pages",
        type=str,
        nargs="*",
        metavar="EXTRA_REPO_URL",
    )
    parser.add_argument(
        "-i",
        "--info",
        help="show repository information",
        action="store_true",
        default=False,
    )

    sp = parser.add_subparsers(dest="cmd")

    wt = sp.add_parser("worktree")
    wt.add_argument(
        "-c",
        "--create",
        help="create a new worktree",
        type=str,
        default=argparse.SUPPRESS,
        metavar="BRANCH_NAME",
        dest="worktree_create",
    )
    wt.add_argument(
        "-r",
        "--remove",
        help="remove a worktree",
        type=str,
        default=argparse.SUPPRESS,
        metavar="BRANCH_NAME",
        dest="worktree_remove",
    )

    args = parser.parse_args()
    if args.setup and not args.url.startswith(("git", "http")):
        raise parser.error(
            f"--setup(-s) requires a full URL got '<owner>/<repo>' shorthand: {args.url!r}"
        )
    if not args.url.startswith(("git", "http")):
        target = root / args.url
        if not target.exists():
            raise parser.error(
                f"passed shorthand for --url(-u) but {target} doesn't exist, setup it first"
            )
        if not (target / ".git").exists():
            raise parser.error(f"directory {target} is not git managed")
    return args


def main(args: argparse.Namespace, root: Path):
    m = Manager(root, args.url)
    if args.setup:
        p = m.setup()
        print(f"reference repository is at {p}")
    if args.wiki is not None:
        combine_wiki([m] + [Manager(root, url) for url in args.wiki], m.wiki_all)
        print(f"all wiki pages are at {m.wiki_all}")
    if args.info:
        m.info()
    if args.cmd is None:
        return
    if args.cmd == "worktree":
        if b := getattr(args, "worktree_create", None):
            p = m.worktree_add(b)
            print(f"worktree repository is at {p}")
        if b := getattr(args, "worktree_remove", None):
            m.worktree_remove(b)
            print("worktree removed")


if __name__ == "__main__":
    root = Path(os.getenv("XDG_PROJECTS_DIR") or "~/Projects").expanduser()
    args = parse_args(root)
    main(args, root)
