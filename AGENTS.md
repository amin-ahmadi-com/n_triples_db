# Publishing to pub.dev

Run all commands from the project root (where this file lives).

## Checklist

1. **README.md** — ensure the version in `pubspec.yaml` matches the one in the example usage
2. **CHANGELOG.md** — add a new version entry summarizing changes (follow the existing format)
3. **pubspec.yaml** — bump the `version` field
4. **Tests** — run `flutter test` and confirm 0 failures / 0 warnings
5. **Analyze** — run `flutter analyze` and fix any lints/warnings
6. **Dry run** — run `dart pub publish --dry-run` to validate for pub.dev

Do not actually publish — only perform the dry run.

## Version Bumping

- If the user did not specify a version number, ask them for it before proceeding
- Follow semver: patch (bug fixes), minor (new features), major (breaking changes)
