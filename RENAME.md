# Renaming the project

The project is named **Odinarcade** (display name). Its machine form, used for
the folder, binary, and `PROJECT_NAME`, is `odinarcade`.

## Single source of truth (code)

| File | Line | What |
| --- | --- | --- |
| `meta/meta.odin` | 5 | `PROJECT_NAME :: "odinarcade"`: used by the CLI banner (upper-cased at runtime), `--version`, and `--help` usage line |

Nothing else in Odin source contains the name; the CLI reads `meta.PROJECT_NAME`.

## Other places the name appears

| File | Line(s) | What |
| --- | --- | --- |
| `README.md` | 1 | Title heading (`Odinarcade`) |
| `README.md` | 75–79 | Build output path `build/odinarcade` and run examples |
| `README.md` | 85 | Sample demo output banner `ODINARCADE` (upper-case form) |
| `README.md` | 117–118 | Development build commands (`-out:build/odinarcade`) |
| `.github/workflows/ci.yml` | 18 | `BIN: build/odinarcade` (binary output path) |
| `RENAME.md` | throughout | This file |
| repository directory | n/a | The checkout folder is named `odinarcade` |

## Package / collection naming

Odin packages are named after their **role**, not the project, so they do not
need to change on rename:

| Directory | Package | Imported as |
| --- | --- | --- |
| `meta/` | `meta` | `"../meta"` |
| `ecs/` | `ecs` | `"../ecs"` |
| `color/` | `color` | `"../color"` |
| `cli/` | `main` | built with `odin build cli` |
| `tests/` | `tests` | run with `odin test tests` |

No `-collection:` flag is used (imports are relative), so there is no collection
name to update. If you later add one (e.g. `-collection:odinarcade=.`), add it
to this table.

## Verify

Before renaming, list every occurrence of the current name (this should match
exactly the places in the tables above, plus this file):

```sh
grep -rnI -i -e 'odinarcade' -e 'odin-arcade' -e 'odin_arcade' -e 'odin arcade' --exclude-dir=.git .
```

After renaming, run the same command with the old name; it should print nothing
except RENAME.md (or nothing at all if you also update this file).
