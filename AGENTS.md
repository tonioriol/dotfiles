# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## CLI Tools for PR/MR Creation

Lives in GitHub, use `gh` CLI
  - Example: `gh pr create --title "feat: add feature" --body "Description of the feature" --head my-feature-branch`

## Git Commit Conventions

- **Commit messages**: Single-line conventional commits (e.g., `feat: add feature`, `fix: resolve issue`)
- **Branch names**: Use descriptive names like `feat/add-feature`, `fix/fix-issue`, or `chore/update-dependencies`.

## Architeture

Always split the task in a TODO, then use orchestrator to create a subtask for each TODO to implement each of them. Unless the task is very small.

* Write the most maintainable code, thinking long term, do not go for hacky, quick solutions. Always go for the most well architected, refactoring when needed, approach. Always consider the big picture, what the app is, and how do we need to adjust everything to keep it maintainable.
* Once we finish a task implementation always identify what ultimately worked, and then review what has been done so we can refactor it and clean it up if we led some stuff that we tried but wasnt ultimatelly the right thing.
* Always remember that we need to be pragmatic and not overengineer things. But always try to keep the code clean and maintainable.
