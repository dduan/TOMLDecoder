## Steps for a new release
- Bump version in `README.md`.
    - version in instruction for SwiftPM
    - version in instruction for Bazel
- In `CHANGELOG.md`, create a section for the new version and move changes from
  the development section there.
- Check in all changes in git.
- Make a new tag for the version number.
- Push all changes and tag to GitHub and make a pull request.
- Make sure CI is green.
- Merge the PR. Make sure the version tag is preserved when this happens.
- Create a GitHub release from the new version tag. Paste in content of
  corresponding change log.
