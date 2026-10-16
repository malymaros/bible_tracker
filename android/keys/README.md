# Release signing key

`release.jks` signs the released app (`sk.marosmaly.bibletracker`,
alias `bibletracker`). It is committed on purpose as the backup: it is
encrypted with its password, which is **not** in the repo - it is saved in
the owner's Google account (Google Password Manager).

On a new PC, write `android/key.properties` (gitignored):

```properties
storeFile=../keys/release.jks
storePassword=<password from Google Password Manager>
keyAlias=bibletracker
keyPassword=<the same password>
```

Every update of the released app must be signed with this key; with a new
one users have to uninstall (and lose their data) first.
