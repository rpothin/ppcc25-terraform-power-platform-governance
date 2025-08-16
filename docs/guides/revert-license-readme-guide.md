# Reverting LICENSE and README.md to Main Branch State

![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)

## Purpose
This guide shows you how to revert the `LICENSE` and `README.md` files at the root of the repository to their state in the `main` branch, especially if they were changed by GitHub Copilot Coding Agent against your instructions.

## Prerequisites
- You have a local clone of the repository
- You are working on a feature branch or pull request
- You have Git installed and configured

## Step-by-Step Instructions

### 1. Identify Modified Files
First, confirm that `LICENSE` and `README.md` have been modified:

```bash
git status
```

Look for `LICENSE` and `README.md` under "Changes not staged for commit" or "Changes to be committed".

### 2. Restore Files from Main Branch
To revert these files to their state in the `main` branch:

```bash
git checkout main -- LICENSE README.md
```

Or, using the modern command:

```bash
git restore --source=main LICENSE README.md
```

### 3. Stage the Reverted Files
Add the reverted files to the staging area:

```bash
git add LICENSE README.md
```

### 4. Commit the Changes
Commit the restoration with a clear message:

```bash
git commit -m "Revert LICENSE and README.md to main branch state"
```

### 5. Push to Remote (if needed)
If you are working on a remote branch:

```bash
git push origin your-branch-name
```

## Troubleshooting
- If you accidentally revert the wrong files, you can undo the last commit:
  ```bash
  git reset HEAD~1
  ```
- Always verify the file contents after restoration:
  ```bash
  git diff main HEAD -- LICENSE README.md
  ```

## Why This Matters
Restoring these files ensures repository integrity and respects user instructions, especially for critical files like `LICENSE` and `README.md`.

## Related Guides
- [Git Reference](../references/git-reference.md)
- [Restoring Files in Git](../guides/restoring-files-guide.md)
