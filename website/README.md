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

The online Bible reader (`mobilne-aplikacie/bible-tracker/biblia/`) is not
committed either: it is generated from the local SSV backup. Make the backup
with `dart run tool/ssv_backup.dart <backup-dir>` (once, about 40 minutes),
then `dart run tool/ssv_site.dart <backup-dir>` and upload the whole
`biblia/` folder (about 1,400 files, 12 MB).
