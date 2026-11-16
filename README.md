# gft, the plugin

The official [tote](https://github.com/totecli/tote) plugin for
[gft](https://github.com/20syldev/gft), the command that shows, downloads and installs GitHub
releases and manages git stashes. It adds to tote:

- on a saved repository (Tab on its row): show the latest release, list its assets, find the asset
  for this machine, show the release notes, compare two releases, download an asset, open the
  releases page, and four stash actions (list, show, drop, delete all);
- in the palette (`Ctrl+K`), for any repository: show a release, show the latest version number,
  compare two releases, open the releases page, download an asset, install a release binary,
  download the source archive, and clear the response cache;
- suggestions on the tag and asset fields, with `Ctrl+L`.

This repository is the plugin only. The program it runs is [gft](https://github.com/20syldev/gft),
which you install separately. tote ships a copy of this plugin and `tote plugin install gft`
installs it; the releases of this repository carry the same plugin, so that it can be updated
between two releases of tote.

## Requirements

| What                                                        | Version                                                                                                                              |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| tote                                                        | 1.1.0 or later (the suggestions of a field, `field.choices_from`). tote 1.0 lists the plugin as incompatible, not as invalid.        |
| [gft](https://github.com/20syldev/gft)                      | 1.3.0 or later. The plugin passes options that gft 1.2 and earlier do not know (`--plain`, `--asset=`, `--user`, `--force`, `--pre=`, `--no-cache=`, `--checksum=`, `--dir=`, `--source=`). |

With gft 1.2 most actions fail with `Unknown option`, and the suggestions fail with the same line
shown next to the reason. Only the stash actions and `Open the releases page` still work. Install or
upgrade gft first. When gft is not installed at all, the plugin
is in the state `missing-dependency` and offers nothing.

## Install

The copy that ships with tote:

```sh
tote plugin install gft
```

tote prints what the plugin runs and what it may do (see Permissions), then asks `[y/N]`. Without a
terminal, review `tote plugin install gft --dry-run` and pass the `--grant` token it prints.

The official release of this repository, for a tote that ships an older copy, or to update without
waiting for a release of tote. The release holds `plugin-gft.tar.gz` and `plugin-gft.tar.gz.sha256`.
tote needs the checksum of the archive, taken from a place other than the download itself (the notes
of the release, or the `.sha256` file; ask for a second source when it matters):

```sh
tote plugin install https://github.com/totecli/gft/releases/download/1.1.0/plugin-gft.tar.gz \
    --sha256 <the 64 digits of plugin-gft.tar.gz.sha256>
```

The checksum proves that the file is the one that was published. It does not prove who published it.

Use the full URL. The shorthand `totecli/gft@1.1.0` stands for an asset named `gft.tar.gz`, which
this repository does not publish.

## Update

A copy that came from tote is updated by the official release like this, with the URL and the
checksum of the new release:

```sh
tote plugin update gft https://github.com/totecli/gft/releases/download/1.1.0/plugin-gft.tar.gz \
    --sha256 <the 64 digits of plugin-gft.tar.gz.sha256>
```

- tote never asks the network what is new: you give it the release.
- `tote plugin update gft` with no source does not read this repository. For a copy installed from a
  release it stops with `source_required`, and for a copy that came with tote it takes the copy
  inside the tote you run (so nothing newer than that tote). `tote plugin update gft totecli/gft`
  is not a valid source: `owner/repo` alone is refused, the tag is part of the shorthand.
- The tag of a release is the version of `plugin.toml` without `v`, otherwise tote refuses the
  archive (`tag_mismatch`).
- `--dry-run` shows what changes first. An update that only changes a label asks nothing. One that
  asks for a new permission, or changes what a field suggests, asks for consent again.

## Suggestions with Ctrl+L

The fields of a tag (`Tag`, `From tag`, `To tag`) and the field `Asset` are free text. Press
`Ctrl+L` on one of them and a picker lists what gft finds on GitHub; pick a value to fill the field,
or ignore the list and type. A typed value and a picked value are checked the same way, so the
list is help, never a decision.

- The tag fields list the latest releases of the repository (gft prints at most 10), newest first,
  with their date. With `prereleases` on, a pre-release has the word `prerelease` after its date
  (`2026-10-20 prerelease`), and `prerelease` alone when GitHub gives no date.
- The asset field lists the assets of the release named in the field `Tag` (the latest one when
  that field is empty). The asset for this machine comes first, with the label `recommended`.
  Fill the tag before you ask for the assets.
- Nothing starts before the key press. The program is `gft --releases --plain` or
  `gft --assets --detect --plain`, listed in full on the consent screen.
- The suggestions run without `GITHUB_TOKEN` and without any other variable of the plugin, in the
  cache folder of the plugin, and are stopped after 10 seconds (gft gives up after 8, or after
  `GFT_PLAIN_TIMEOUT` seconds). They are anonymous, even when `gh` is logged in, but they still use
  your home directory: gft writes its response cache in `~/.config/gft`.
- The picker narrows to the values that contain what you typed. Esc closes it and keeps the text.
- `Ctrl+L` redraws the screen in many terminals, and a terminal multiplexer or an editor plugin can
  take it before tote sees it. If it does nothing, type the value.

The plugin keeps the exact name of an asset in the field. There is no pattern any more: the
download takes the asset with exactly that name. For `Install a release binary` the asset is
optional, and empty lets gft pick the archive or the binary for this machine.

## Settings

Four settings, in the Plugins screen of tote, in `<config>/plugins/gft.toml`, or in the
environment of tote. The environment wins over the file, and the file over the default. A value that
does not fit is ignored and `tote plugin info gft` says so.

| Setting        | Environment variable           | Default | What it does                                                                                                                                             |
| -------------- | ------------------------------ | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `prereleases`  | `TOTE_PLUGIN_GFT_PRERELEASES`  | `false` | Includes pre-releases in the latest release, in the lists and in the downloads and installs that follow the latest release (`--pre=<value>`).            |
| `checksum`     | `TOTE_PLUGIN_GFT_CHECKSUM`     | `false` | Checks a download against the checksum file of its release (`--checksum=<value>`). This is integrity, not authenticity. A release with no such file fails. |
| `refresh`      | `TOTE_PLUGIN_GFT_REFRESH`      | `false` | Skips the response cache of gft, which keeps answers for 5 minutes (`--no-cache=<value>`).                                                                |
| `download_dir` | `TOTE_PLUGIN_GFT_DOWNLOAD_DIR` | empty   | The folder of the downloads (`--dir=<value>`). Empty means the current directory, the one tote runs in. An absolute path or `~/...` only.                 |

A boolean is `1`, `true`, `yes`, `on` or `0`, `false`, `no`, `off`, in any case. The plugin does not
default `download_dir` to `~/Downloads`, because the name of that folder depends on the language.
There is no `must_exist`: if the folder disappears, gft refuses it and says so, instead of tote
quietly sending the file to the current directory. gft expands a leading `~` itself.

Only an absolute path or `~/...` is accepted. A relative path (`dl`, `../x`) or a value tote cannot
use is ignored, the setting falls back to its default (empty), and the downloads go to the current
directory. `tote plugin info gft` shows the rejection as a warning; check it after you type a path.

A download never replaces an existing file, unless you tick `Replace an existing file` (`--force`).
`Install a release binary` has no such field: gft replaces an installed binary by itself. The name
of the installed file comes from the release, not from you, and `~/.local/bin` is often early on
the `PATH`: the confirmation says that a program of the same name is replaced, so read the asset
first (`Find the asset for this machine`).
`Download the source archive` has no checksum, because an archive of the sources has none.

## Permissions

tote asks for consent before the plugin runs, and shows each permission as `[enforced]` or
`[declared]`. Enforced means tote itself refuses what is not allowed. Declared means the plugin
states it and tote cannot stop a program that runs with your rights: `fs:` and `net:` are declared.

| Permission                                | Why                                                                                                                                                                                                                  |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `exec:gft` (enforced)                     | The only program tote starts. gft itself starts `git`, `gh`, `curl`, `tar`, `unzip` and a few tools of the system, and `git` runs the hooks of the selected repository for the stash actions.                       |
| `env:GITHUB_TOKEN` (enforced)             | Passed to every run of the plugin, stash actions and downloads included (tote cannot narrow it per action). gft leaves it to `gh` (when `gh` is installed and logged in) for the release notes and the tags. It is not passed to the suggestions. |
| `host:read:repos` (enforced)              | The actions use the saved repository (`{repo.slug}`, `{repo.name}`).                                                                                                                                                 |
| `host:open-url` (enforced)                | `Open the releases page`: tote asks before it opens the address.                                                                                                                                                     |
| `derived:tty` (enforced)                  | Downloads and installs take over the terminal to show the progress bar.                                                                                                                                              |
| `fs:write:cwd`                            | A download goes to the current directory, or to the folder of `download_dir`.                                                                                                                                        |
| `fs:write:home`                           | `Install a release binary` copies the binary to `~/.local/bin` (always `--user`, never `/usr/local/bin`) under the name of the program in the release, and replaces a program of the same name. gft also keeps its response cache in `~/.config/gft`. |
| `fs:write:repo`                           | `Drop a stash` and `Delete all stashes` change the `.git` folder of the selected repository.                                                                                                                         |
| `fs:write:tmp`                            | An install downloads and unpacks in a temporary folder, and a checksum file lives there.                                                                                                                             |
| `fs:read:cwd`, `fs:read:repo`             | gft looks at the files of the current directory before it writes, and the stash actions read the repository.                                                                                                         |
| `fs:read:home`                            | gft reads its own response cache, and `gh` reads its login (`~/.config/gh`) when gft asks it for the release notes.                                                                                                  |
| `net:github.com`, `net:api.github.com`, `net:codeload.github.com`, `net:*.githubusercontent.com` | The pages, the API, the source archives (`github.com` redirects them to `codeload.github.com`) and the download servers of the release assets. |

The consent screen flags `fs:read:home`, `fs:write:home`, `net:*.githubusercontent.com` and
`env:GITHUB_TOKEN` with a `!`, and so it does for the terminal takeover. The plugin used to declare `fs:write:any`, which said that gft could
write anywhere; this version says where.

A download folder outside your home directory is your own decision: `download_dir` is a setting,
nothing in tote or in the plugin limits it, and the consent screen cannot list a path that you will
type later. gft refuses a folder that does not exist or is not writable, and never creates it.

## Limits

- **Private repositories give no suggestions.** The list is read from the public pages of GitHub,
  without a token. You can still type the tag and the asset. What gft asks `gh` for (release notes,
  tags) can use your login.
- **A missing and a private repository look the same.** gft cannot tell them apart without a
  token, so the picker shows `Repository not found or private: <repo>`. Check the name of the
  repository, and remember that a private one has no suggestions.
- **Some tags cannot be used.** A tag holds letters, digits and the separators `. _ + @ -`, with no
  `..`, no `/` and no leading dash, so that it cannot be taken for an option or for a range.
  Scoped tags of a monorepo such as `@scope/pkg@1.0.0` are hidden from the list, and refused when
  typed: use gft in a terminal for them.
- **One English word.** `recommended` (assets) is printed by gft in English and tote shows a label
  as the program wrote it, beside French texts. This is accepted. So is `prerelease`, the word that
  gft puts after the date of a pre-release when `prereleases` is on: it is part of the label, never
  of the tag that fills the field.
- **GitHub can refuse.** gft reads the pages of GitHub. A burst of requests, especially with
  `refresh` on, can be answered with an error for a while: the picker then says why, and the cache
  of 5 minutes helps.
- **Release order.** Install gft 1.3 before this plugin. gft 1.2 does not know the arguments.

## Check it yourself

This repository is not itself a package (tote refuses a folder that holds `tools/` or `dist/`), so
build the archive and check that:

```sh
tools/package.sh                      # dist/plugin-gft.tar.gz, its .sha256, and the sha256 printed
tote plugin check ./dist/plugin-gft.tar.gz --strict --official
tote plugin check ./dist/plugin-gft.tar.gz --official --argv --repo <saved repository> \
    --set tag=v2.104.0 --set asset=gh_2.104.0_linux_amd64.tar.gz
```

`--strict` fails on any warning and on a missing translation. `--official` lets the check accept the
id `gft`, which is reserved for the copy of tote and for the releases of `totecli/gft`. `--argv`
prints the command each contribution would run and starts nothing. `TOTE_BIN=<tote> tools/package.sh`
runs the first check for you.

For the same reason a local `tote plugin install ./dir` refuses the id `gft`. To read the consent
screen, unpack the archive, change `id = "gft"` to another id, and run
`tote plugin install ./dir --dry-run` in a scratch environment (`TOTE_CONFIG_DIR`, `TOTE_DATA_DIR`,
`TOTE_STATE_DIR`, `TOTE_CACHE_DIR` and `HOME` set to an empty folder).

## Release

1. Raise `version` in `plugin.toml`, run `tools/package.sh` with a tote 1.1 or later, and read
   `tote plugin install` of a copy under another id.
2. Commit, then tag the commit with the version, without `v` (`1.1.0`). The workflow
   `.github/workflows/release.yml` runs on a tag only: it downloads the release of tote named in the
   file, checks its signature and checksum, builds the archive again, checks it, and creates a
   **draft** release with `plugin-gft.tar.gz` and `plugin-gft.tar.gz.sha256`.
3. Read the draft, add the notes and publish it. Print the checksum in the notes.
4. tote vendors the release with `scripts/vendor.sh gft <tag> <sha256>`.

## Conventions

- Public text (the manifest, this file, comments) is in English. `locales/fr.toml` is in French,
  with a no-break space (U+00A0) before `?`, `!`, `:` and `;` and inside guillemets.
- `locales/en.toml` holds only the English labels that the manifest cannot carry (the values of a
  `choice`). The keys of both catalogs are sorted (`LC_ALL=C sort`) and must stay in sync:
  `tote plugin check --strict` reports a missing or an extra key.
- The tag is the version of `plugin.toml`, without `v`.
- A commit is one line, `SEVERITY: scope: Description`, with the severity MAJOR, MEDIUM, MINOR,
  BUILD or DOC and the scope plugin, ci, i18n, docs or tools (BUILD and DOC have none).

## License

[MIT](LICENSE).
