# Bible Tracker - website page

Source of https://marosmaly.sk/mobilne-aplikacie/bible-tracker/ - the
folder mirrors the path on the server (Websupport hosting, uploaded with
WinSCP).

The APK is not committed (see `.gitignore`): build the release
(`flutter build apk --release`) from a checkout at a path without personal
names (the build path ends up in the APK), e.g.
`git worktree add --detach C:\b\bt release/<version>`; copy it here as
`mobilne-aplikacie/bible-tracker/bible-tracker-<version>.apk` and update the
version, size and SHA-256 in `index.html`.

The site's homepage, the app list (/mobilne-aplikacie/) and `.htaccess` are
not in this repo.
