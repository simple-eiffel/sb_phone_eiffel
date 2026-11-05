# SB Phone in Eiffel

[The Kotlin app](https://github.com/simple-eiffel/sb_phone) •
[simple_eif_phone](https://github.com/simple-eiffel/simple_eif_phone) •
[Issues](https://github.com/simple-eiffel/sb_phone_eiffel/issues)

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Eiffel 25.02](https://img.shields.io/badge/Eiffel-25.02-purple.svg)
![DBC: Contracts](https://img.shields.io/badge/DBC-Contracts-green.svg)

[SB Phone](https://github.com/simple-eiffel/sb_phone), a free, offline Bible-study app for Android, rebuilt one to one in Eiffel with [simple_eif_phone](https://github.com/simple-eiffel/simple_eif_phone).

The Kotlin app remains the app people use. This project answers a question: can a real application, not a demo, be written entirely in Eiffel for a phone?

## Status

**0.1.0: every screen works. Not yet a replacement for the Kotlin app.**

- 85 tests pass on a PC. Their expected values come from the Kotlin classes.
- The main screens were compared with the Kotlin app on an emulator, at the default font size and at 1.5.
- It has been used on one real phone: reading, search, notes, highlights, read-aloud in English, Hebrew and Greek, private packs, the timeline, the atlas, and export and import.
- Installing it over the Kotlin app, so that notes carry across, has not been tried.

## What it does

The same as the Kotlin app: a reader of public texts, original-language word study, search, a library of notes and marks, memory cards, a prayer list, a timeline, an empires atlas, private packs, and read-aloud. See [its README](https://github.com/simple-eiffel/sb_phone) for the full list, and its rules: no network permission, no ads, no accounts, and every fact names its source.

## Known differences from the Kotlin app

- Verse rows sit 1 px closer.
- The verse sheet stops above the phone's navigation bar. Kotlin's draws under it.
- The launcher icon is a square picture, not an adaptive icon.
- There is no loading spinner, because queries run in line.
- Reading a pack document aloud does not mark the paragraph being read.
- History, Notes and Highlights build all their rows at once. Only Search adds them in batches.
- A menu too tall for the space below its button stays under the button.

## Building

You need what the [`simple_phone_calc` how-to](https://github.com/simple-eiffel/simple_phone_calc/blob/main/HOWTO.md) lists, and `simple_eif_phone` 0.5.3 or later, with these beside it under `SIMPLE_EIFFEL`: `simple_mml`, `simple_encoding` and `simple_sql`.

**The database is not in this repository.** `assets/app.db` is 217 MB, and like the Kotlin project's it is a build artifact. Build it with the Kotlin project's `datapack`, as its README explains, and copy it to `assets/app.db`. That step needs source databases that are in neither repository, and the rights gate that decides what may ship lives there too.

Then:

```
eifphone build .
```

The app installs beside the Kotlin app: its id is `io.github.ljr1981.sbphone.eiffel`, and its name on the phone is "SB Eiffel".

## Layout

```
src/fold/    the same word folding and query rules as the Kotlin app
src/data/    the databases, notes, packs and export
src/app/     the screens
testing/     the tests
```

To run the tests, build the `sb_phone_eiffel_tests` target from this folder. They need `SB_APP_DB` set to a copy of `app.db`, and `testing/pc_sqlite/build_fts4.bat` run once to build SQLite for the PC.

The `sb_fold_diff` and `sb_data_diff` targets compare this code with the real Kotlin classes. Their harness is tied to one machine, so it is not in this repository.

## License

MIT License. See the LICENSE file. The Ezra SIL font in `assets` has its own license, in `assets/licenses`.
