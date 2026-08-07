# Workspace Customization Rules

- **Linting Rule**: After executing any commands or making code changes, always run the appropriate linter/analyzer (e.g., `flutter analyze`) and proactively fix any problems in the problems tab to ensure a clean codebase.
- **Maintenance Rule**: At the end of every day (or as a regular maintenance step), remove any dead code within the project.
- **Testing Rule**: After executing commands that modify logic, automatically update the test cases to ensure they reflect the new changes and pass successfully.
- **Version Control Rule**: Commit code using git after every command or significant set of changes.
- **Security & Secrets Rule**: Never commit secrets (API keys, passwords, credentials) to version control. Always use environment variables (e.g., `.env`), and ensure sensitive files are explicitly added to `.gitignore`.
- **Documentation Rule**: Whenever a new dependency, environment variable, or major feature is introduced, update the `README.md` or system architecture documentation to keep it current.
- **Formatting Rule**: Always run the appropriate code formatter (e.g., `dart format`) before committing to maintain consistent, readable code styles across the project.
- **Modularity Rule**: Keep functions and UI widgets focused on a single responsibility. Proactively extract large, complex code blocks into smaller, reusable components.
- **Dependency Management Rule**: When adding new dependencies, verify they are actively maintained, and always explicitly declare their versions rather than using loose constraints.
