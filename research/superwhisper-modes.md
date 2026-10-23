# How Superwhisper stores and syncs modes

Research note. Checked October 2026 against the official docs, the changelog, the official `superwhisper-optimize` agent skill, and the public feedback board. Superwhisper was not installed on the machine used for this research, so nothing here comes from inspecting real files.

## Short answer

- **Storage:** one plain folder of JSON. Each mode is its own `modes/<key>.json`. Vocabulary, replacements and the list of registered modes share a single `settings/settings.json`.
- **Relocating:** yes, on macOS, with **App folder location → Change folder**. The docs warn against iCloud-synced locations: the folder must stay local.
- **iPhone:** modes do not reach the iPhone. The docs say iOS modes and vocabulary are per device and cloud sync is "planned". Filesync syncs Mac to Mac only. There is no documented mode import or export.
- **External prompt or vocab files:** not supported. Prompts are inline strings in the mode JSON, and vocabulary is an array in `settings.json`. Loading a prompt from a file or URL is an open feature request.
- **Diffability:** the files are hand-editable JSON, and the vendor's own skill tells agents to edit them. Some things count against diffing: random mode keys, `id` fields on replacements, a shared `settings.json` that mixes personal vocab with config, and possible formatting churn when the app saves. None of the sources document key order or timestamps.

## 1. Where things live (macOS)

| What | Where | Source |
| --- | --- | --- |
| App folder (default, new installs since 2.16.4, Jul 2026) | `~/superwhisper` | [changelog](https://superwhisper.com/changelog), [Advanced settings](https://superwhisper.com/docs/get-started/settings-advanced) |
| App folder (older installs) | `~/Documents/superwhisper` | [Advanced settings](https://superwhisper.com/docs/get-started/settings-advanced) |
| Custom folder location | stored in macOS defaults: `defaults read com.superduper.superwhisper appFolderDirectory` (parent dir; the app appends `superwhisper`) | [Optimizing with AI](https://superwhisper.com/docs/get-started/optimizing-with-ai), [superwhisper-optimize SKILL.md](https://github.com/superultrainc/superwhisper-docs/blob/main/skills/superwhisper-optimize/SKILL.md) |
| Modes | `modes/`: one JSON file per mode, filename = `key` (e.g. `custom-KQRT.json`) | [mode-schema.md](https://github.com/superultrainc/superwhisper-docs/blob/main/skills/superwhisper-optimize/references/mode-schema.md), [Switching modes](https://superwhisper.com/docs/modes/switching-modes) |
| Vocabulary, replacements, `modeKeys` and other settings | `settings/settings.json` (one file) | [mode-schema.md](https://github.com/superultrainc/superwhisper-docs/blob/main/skills/superwhisper-optimize/references/mode-schema.md), [Backing up settings](https://superwhisper.com/docs/get-started/backing-up-settings) |
| Custom model configs | `models/` | [Backing up settings](https://superwhisper.com/docs/get-started/backing-up-settings) |
| History / audio | `recordings/` | [Backing up settings](https://superwhisper.com/docs/get-started/backing-up-settings) |

### Mode file format

From the official schema reference, which says it is "taken from real mode files":

- Top-level keys include `key`, `name`, `type` (`message`/`custom`/`super`/`voice`), `prompt`, `tone`, `language`, `voiceModelID`, `languageModelID`, `contextFromSelection`, `contextFromClipboard`, `contextFromActiveApplication`, `activationApps`, `activationSites`, `diarize`, `useSystemAudio`, `promptExamples`, `contextTemplate`, `script`, `scriptEnabled`, `version`, among others.
- A new mode needs two things. The file's `key` must equal its filename, and the key must be appended to the `modeKeys` array in `settings/settings.json`: "Without this the app never loads the mode."
- Restart the app after editing files so it picks up the changes ([SKILL.md](https://github.com/superultrainc/superwhisper-docs/blob/main/skills/superwhisper-optimize/SKILL.md)).

Vocabulary can also be managed with the official CLI (`superwhisper vocab add|remove|list`, `superwhisper snippets ...`, `--settings <path>`) ([CLI docs](https://superwhisper.com/docs/get-started/cli)). The app can also bulk-add vocabulary with **Import CSV** ([Vocabulary docs](https://superwhisper.com/docs/get-started/interface-vocabulary)).

## 2. Relocating the folder

- Use **Settings → Configuration → Advanced settings → App folder location → Change folder...** to choose a location. The setting has existed since 1.25.0 (Jan 2024). It is macOS only: Windows always uses `%LOCALAPPDATA%\com.superwhisper.app` ([Advanced settings](https://superwhisper.com/docs/get-started/settings-advanced), [changelog](https://superwhisper.com/changelog), [Windows docs](https://superwhisper.com/docs/get-started/windows)).
- The docs say: "Superwhisper uses this folder actively during dictation, so keep it locally accessible on your device." ([Advanced settings](https://superwhisper.com/docs/get-started/settings-advanced))
- **iCloud Drive is discouraged.** The troubleshooting page says iCloud Documents syncing can move the folder, and then new modes fail to save. The fix is to "point Superwhisper at a folder outside iCloud" ([Unable to create mode](https://superwhisper.com/docs/common-issues/unable-to-create-mode)). This problem is why the default moved out of `~/Documents`.
- **A symlink is not documented.** One option would be to keep the folder local and symlink selected files into a repo, or the other way round. Nothing in the docs says whether the app follows a symlinked `modes/` folder or writes through it, so test this before relying on it.

## 3. Getting modes to the iPhone

- **Official position:** "Modes and vocabulary are stored per device. They don't sync from your Mac or PC yet. Cloud sync is planned. Recreate your most-used modes in the iOS app's Modes settings." ([iOS docs](https://superwhisper.com/docs/get-started/ios))
- **Filesync:** "Syncs your Superwhisper configuration files across all installations registered under the same license" ([Advanced settings](https://superwhisper.com/docs/get-started/settings-advanced)). It shipped in 1.47.0 (Jun 2025) as "Syncing now available between Macs for modes, models and vocabulary" ([changelog](https://superwhisper.com/changelog)). It runs through Superwhisper's own servers, not iCloud ([Security docs](https://superwhisper.com/docs/security/sensitive-data), [Account deletion](https://superwhisper.com/docs/security/account-deletion)). It covers Mac only, not iOS or Windows ([Unable to create mode](https://superwhisper.com/docs/common-issues/unable-to-create-mode)).
- **iCloud:** not a supported transport. One user reports that the iOS app "ignores it entirely" even when the Mac folder sits in iCloud Drive ([feedback: synchronize across devices](https://feedback.superwhisper.com/board/p/synchronize-across-devices), status "In Progress").
- **Import/export:** I found no documented mode import or export on either platform. The feedback board has a request for bulk export, and one comment notes that sharing modes "one by one" is "painful and error prone".
- **Community workarounds (unverified):** these come from the same feedback thread.
  - One user says iOS storage is file-based and visible in the Files app. They stage settings in iCloud Drive and copy them onto the phone with an iOS Shortcut. They also report that "every replacement entry needs an `id` field" or the file is rejected.
  - Another user copied the configuration files from iPhone to Mac by hand.

## 4. Keeping personal terms out of a public repo

- **Prompts:** the `prompt` field is an inline string in the mode JSON. No include or file-reference mechanism is documented. A feature request asks to "load custom instructions from files or URLs" and mix "a shared base prompt (URL) with personal additions (local file)". It is still **Pending**, with no staff reply ([feedback](https://superwhisper.userjot.com/board/p/load-custom-instructions-from-files-or-urls----edit-in-your)).
- **Vocabulary:** lives only in `settings/settings.json` as a `vocabulary` array, together with `replacements` and `modeKeys`. It is global, not per mode. Import or export in CSV/JSON/TXT is an open request ([feedback](https://superwhisper.userjot.com/board/p/allow-import-export-of-vocabulary)), though CSV import has since shipped ([changelog](https://superwhisper.com/changelog)).
- **What this implies:** to keep personal terms private, the repo has to hold templates and build the real files.
  - Commit mode JSON with no personal content.
  - Keep vocab and private prompt fragments in a gitignored file.
  - Apply them with a small script, either through the official CLI (`superwhisper vocab add`, `snippets set`) or by merging into `settings.json` and the mode files.
  - Never commit `settings.json`.

## 5. Diffing and hand-editing

What helps:
- Everything is plain JSON with one file per mode. The vendor's own agent skill creates mode files and edits `settings.json` by hand ([SKILL.md](https://github.com/superultrainc/superwhisper-docs/blob/main/skills/superwhisper-optimize/SKILL.md)). The docs also tell users to edit mode JSON and Quick Look it.
- In the official schema sample, keys are alphabetically sorted and pretty-printed. That matches Swift `JSONEncoder` with `.sortedKeys`, which would give stable key order. This is an inference, not documented.

What hurts:
- **Random keys:** mode keys carry a random suffix (`custom-XXXX`), and each one must be mirrored in `modeKeys`.
- **Replacement ids:** replacement entries reportedly carry `id` fields, probably UUIDs (community report, see above).
- **One shared settings file:** `settings.json` mixes app preferences, the mode registry, vocabulary and replacements. Diffs there are noisy and personal.
- **Formatting churn:** a community project claims mode files must use Apple-style JSON spacing (`"key" : value`) and that standard `json.dump` output "silently fails" ([tomevault Haqbani/superwisper](https://tomevault.io/tome/Haqbani/superwisper); the site was down when checked, so this is quoted from the search index). The official sample uses normal `": "` spacing, so treat the claim as unconfirmed. Either way, if the app re-serialises files on save (Swift `JSONEncoder` prints `"key" : value`), hand-formatted files will show whitespace diffs the first time the app saves them.
- **Undocumented:** nothing says whether the app rewrites files it didn't change, or stamps timestamps into mode files. A `version` field exists. The changelog mentions a `meta.json`, but in the recordings context.

**To verify on a real install:**
1. Edit a mode in the UI and `git diff` the folder, to see whether untouched files change and whether the order is stable.
2. Check whether a symlinked `modes/` folder survives.
3. Find where iOS stores files in the Files app.

## Sources

- https://superwhisper.com/docs/get-started/settings-advanced
- https://superwhisper.com/docs/get-started/backing-up-settings
- https://superwhisper.com/docs/get-started/ios
- https://superwhisper.com/docs/common-issues/unable-to-create-mode
- https://superwhisper.com/docs/modes/switching-modes
- https://superwhisper.com/docs/get-started/interface-vocabulary
- https://superwhisper.com/docs/get-started/cli
- https://superwhisper.com/docs/get-started/optimizing-with-ai
- https://superwhisper.com/docs/llms-full.txt (full docs dump, used for search)
- https://superwhisper.com/changelog (2.16.4 default folder move; 1.47.0 Mac sync; 1.25.0 custom folder)
- https://github.com/superultrainc/superwhisper-docs/blob/main/skills/superwhisper-optimize/SKILL.md
- https://github.com/superultrainc/superwhisper-docs/blob/main/skills/superwhisper-optimize/references/mode-schema.md
- https://feedback.superwhisper.com/board/p/synchronize-across-devices
- https://superwhisper.userjot.com/board/p/load-custom-instructions-from-files-or-urls----edit-in-your
- https://superwhisper.userjot.com/board/p/allow-import-export-of-vocabulary
- https://tomevault.io/tome/Haqbani/superwisper (community, unverified)
