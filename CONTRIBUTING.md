# Contributing to Wyrd

Thank you for your interest.

Wyrd is **source-available** under the [PolyForm Strict License 1.0.0](LICENSE.md). That
license does not grant anyone the right to make changes or new works based on the software, so
code contributions can only be accepted from people who have signed a separate written
contributor agreement with the author.

## What you can do

- **Report a bug.** Open an issue with steps to reproduce, platform (Android / iOS / Web, with browser and OS), app language (English / Persian), and expected versus actual behaviour.
- **Suggest a feature.** Open an issue describing the problem it solves, not only the solution.
- **Report a translation problem.** Persian and English copy are reviewed by humans; tell us
  where a string reads wrong, is truncated, or breaks right-to-left layout.
- **Report a security issue privately.** Do not open a public issue. Use GitHub's private
  vulnerability reporting on this repository.

## Commit conventions (for maintainers)

The project uses [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <imperative summary>

<optional body explaining what and why>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.
Scopes follow the repository layout: `app`, `engine`, `backend`, `l10n`, `design`, `docs`.

Each commit should build, pass analysis, and do one thing.
