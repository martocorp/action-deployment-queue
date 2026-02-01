# Code Style

## YAML Formatting

Code should be formatted using yamllint. The configuration file is located at `.yamllint` in the root of the repository.

### Running the Linter

```bash
make lint
```

### Key Guidelines

- Use 2 spaces for indentation
- Avoid trailing whitespace
- Use lowercase for keys
- Use descriptive names for workflow steps

## Shell Scripts

The action contains embedded shell scripts in `action.yml`. Follow these guidelines:

- Use double quotes for variable expansion
- Check required variables with explicit error messages
- Exit with non-zero status on errors
- Use meaningful variable names

## Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `chore:` for maintenance tasks

## Pull Requests

- Create feature branches from `main`
- Use descriptive branch names: `feat/description`, `fix/description`
- Ensure all linting checks pass before requesting review
