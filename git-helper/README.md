# git-helper

An interactive Bash script to streamline staging, committing, and pushing changes in a Git repository.

## Features

- Checks whether you're inside a Git repository
- Lists unstaged modified files and untracked files separately
- Lists already staged files separately so you know what's going to be committed
- Interactive file selection (pick by number, or select all with `A`)
- Safely handles filenames with spaces, quotes, newlines, and names starting with `-`
- Commits only the selected files (`git commit --only`) so pre-existing staged changes aren't accidentally swept into the commit
- Validates commit messages and aborts safely on failure
- Optional push (can skip with `--no-push`)
- Proper error handling and exit codes

## Usage

From a Git repository:

```bash
./git-helper.sh
# or
/path/to/git-helper.sh
```

### Flags

| Flag | Description |
|---|---|
| `--no-push` | Commit without pushing to the remote |
| `-h`, `--help` | Show help text |

## Example workflow

1. Run the script - it displays modified, staged, and untracked files
2. Select files to commit (e.g., `1 2 3` or `A` for all unstaged+untracked files shown)
3. Confirm your selection
4. Enter a commit message
5. Confirm/abort the commit
6. Push (unless `--no-push` is used)

## Notes

- The script only stages the files you select at prompt time. Already-staged files are shown for visibility but are *not* re-staged by the selection prompt.
- Using `git commit --only` means only the files you selected in this run will be included in that commit; staged files not selected remain staged in your index.
- Conflicted files (`UU`) are shown as conflicted and must be resolved before staging/committing.

## Requirements

- Bash 4+
- Git

## Author

Alex Llama

## Generated with

Gemini CLI
