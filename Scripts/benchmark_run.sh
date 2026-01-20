#!/bin/bash
set -euo pipefail

export TOMLDECODER_BENCHMARKS=1

baseline=$(git rev-parse "$1")
target=$(git rev-parse "$2")
repo_root=$(git rev-parse --show-toplevel)
baseline_dir="$repo_root/.benchmarkBaselines/TOMLDecoderBenchmarks/$baseline"
target_dir="$repo_root/.benchmarkBaselines/TOMLDecoderBenchmarks/$target"
worktree_root="$repo_root/.benchmarkWorktrees"
baseline_worktree="$worktree_root/baseline"
target_worktree="$worktree_root/target"

mkdir -p "$repo_root/.benchmarkBaselines" "$worktree_root"

ensure_worktree() {
    local worktree_path="$1"
    local sha="$2"

    if [ -d "$worktree_path" ]; then
        if ! git -C "$worktree_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            echo "Path exists but is not a git worktree: $worktree_path" >&2
            exit 1
        fi
        if ! git -C "$worktree_path" diff --quiet || ! git -C "$worktree_path" diff --cached --quiet; then
            echo "Worktree has local changes: $worktree_path" >&2
            exit 1
        fi
        if [ "$(git -C "$worktree_path" rev-parse HEAD)" != "$sha" ]; then
            git -C "$worktree_path" checkout -q --detach "$sha"
        fi
    else
        git -C "$repo_root" worktree add -q --detach "$worktree_path" "$sha"
    fi

    if [ ! -e "$worktree_path/.benchmarkBaselines" ]; then
        ln -s "$repo_root/.benchmarkBaselines" "$worktree_path/.benchmarkBaselines"
    fi
}

if [ -d "$baseline_dir" ]; then
    echo "Reusing baseline for $baseline" >&2
else
    ensure_worktree "$baseline_worktree" "$baseline"
    (cd "$baseline_worktree" && \
        swift package -c release --allow-writing-to-package-directory \
            --allow-writing-to-directory "$repo_root/.benchmarkBaselines" \
            benchmark baseline update "$baseline" --grouping metric --no-progress 1>&2)
fi

if [ -d "$target_dir" ]; then
    echo "Reusing baseline for $target" >&2
else
    ensure_worktree "$target_worktree" "$target"
    (cd "$target_worktree" && \
        swift package -c release --allow-writing-to-package-directory \
            --allow-writing-to-directory "$repo_root/.benchmarkBaselines" \
            benchmark baseline update "$target" --grouping metric --no-progress 1>&2)
fi
