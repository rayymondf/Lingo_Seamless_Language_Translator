# Lingo File Documentation

This document explains what each file in the Lingo Chrome extension does. Use it when you want to understand the codebase file by file. For the broader project overview, setup steps, APIs, and improvement ideas, read [README.md](README.md).

## File Map

```text
Lingo-Seamless_Language_Translator/
  .gitattributes
  backendService.js
  FILE_DOCUMENTATION.md
  languageSelector.js
  logo(white).png
  manifest.json
  panel.html
  README.md
  sidePanelServiceWorker.js
  styles.css
```

## `.gitattributes`

This file controls Git line-ending behavior.

```text
* text=auto
```

That setting lets Git normalize text files across Windows, macOS, and Linux.

## `manifest.json`

This is the main Chrome extension configuration file. Chrome reads it first to understand the extension's name, permissions, side panel entry point, background service worker, and icons.

Important fields:

- `manifest_version`: Uses Manifest V3.
- `name`: Sets the extension name to `Lingo - Language Translator`.
- `version`: Sets the current version to `1.0`.
- `description`: Describes the extension as a DeepL-powered translator.
- `permissions`: Requests `sidePanel` and `storage`.
- `host_permissions`: Allows requests to `https://api-free.deepl.com/*`.
- `icons`: Uses `logo(white).png` for extension icons.
- `background.service_worker`: Loads `sidePanelServiceWorker.js`.
- `side_panel.default_path`: Loads `panel.html` in the side panel.
- `action.default_title`: Sets the toolbar title to `Open Lingo`.

Without this file, Chrome would not know how to install or run the extension.

## `panel.html`

This file defines the visible side panel interface.

It contains:

- The app title and intro text.
- The source text textarea.
- A live character count.
- The target language dropdown.
- The `Translate` button.
- The `Copy` button.
- The readonly translation output textarea.
- A status message area for loading, success, and error text.
- A recent translations section.
- A `Clear` button for local history.

Important element IDs:

- `textInput`: Source text entered by the user.
- `characterCount`: Displays the current source text length.
- `targetLanguage`: Dropdown populated by `languageSelector.js`.
- `translateBtn`: Starts translation.
- `copyBtn`: Copies the translated result.
- `translationInput`: Displays the translated result.
- `statusMessage`: Shows user-facing status and error messages.
- `historyList`: Holds rendered local history items.
- `emptyHistory`: Shows when there is no saved history.
- `clearHistoryBtn`: Clears saved recent translations.

At the bottom, it loads:

```html
<script src="languageSelector.js"></script>
<script src="backendService.js"></script>
```

The order matters because `languageSelector.js` exposes the DeepL API key value on `window.lingoDeepLAuthKey`, and `backendService.js` uses that value for translation requests.

## `styles.css`

This file styles the side panel.

Main responsibilities:

- Defines shared colors and spacing with CSS variables.
- Sets global `box-sizing`.
- Styles the body background, font, and padding.
- Sizes the main `.panel`.
- Styles the header, title, and intro text.
- Styles card containers, labels, textareas, selects, and buttons.
- Adds focus and hover states.
- Styles the status message states.
- Styles recent translation history items.
- Adds a small responsive layout adjustment for narrow side panel widths.

The CSS is standalone. It does not use Bootstrap, Tailwind, or any external stylesheet.

## `languageSelector.js`

This file manages the target language dropdown and shared DeepL key value.

Main responsibilities:

- Selects the `targetLanguage` dropdown.
- Stores the current DeepL auth key in `DEEPL_AUTH_KEY`.
- Exposes the key as `window.lingoDeepLAuthKey` so `backendService.js` can use the same value.
- Defines a fallback language list for cases where the DeepL language request fails.
- Reads the user's last selected target language from Chrome storage.
- Calls DeepL's target languages endpoint.
- Converts each language into an `<option>`.
- Renames DeepL's `ZH` option to `Chinese (generic)`.
- Restores the user's last selected language when possible.
- Dispatches a `change` event after loading languages so the rest of the UI can update.

Important functions:

- `hasChromeStorage()`: Checks whether `chrome.storage.local` is available.
- `readLastTargetLanguage()`: Reads the saved target language from browser storage.
- `languageName(language)`: Normalizes language display names.
- `populateLanguages(languages)`: Rebuilds the dropdown options.
- `loadLanguages()`: Fetches languages from DeepL, falls back if needed, and restores saved selection.

## `backendService.js`

This file handles the main app behavior after the panel loads.

Main responsibilities:

- Reads and writes local browser storage.
- Restores draft text when the panel opens.
- Restores recent translation history.
- Updates the character counter.
- Enables and disables buttons based on current state.
- Sends translation requests to DeepL.
- Displays translated output.
- Shows clear loading, success, and error messages.
- Saves successful translations to recent history.
- Renders clickable history items.
- Copies translated text to the clipboard.
- Clears saved recent history.

Important constants:

- `MAX_HISTORY_ITEMS`: Limits recent history to 8 saved translations.
- `STORAGE_KEYS`: Defines storage keys for draft text, history, and target language.

Important functions:

- `readStoredValue(key, fallbackValue)`: Reads from `chrome.storage.local`, with a `localStorage` fallback for non-extension testing.
- `writeStoredValue(key, value)`: Writes to `chrome.storage.local`, with a `localStorage` fallback.
- `setStatus(message, type)`: Updates the status message and visual state.
- `updateCharacterCount()`: Updates the character count beside the input label.
- `updateControls()`: Enables or disables `Translate` and `Copy`.
- `renderHistory()`: Builds the recent translations list in the UI.
- `saveToHistory(sourceText, translatedText)`: Saves a successful translation locally.
- `getDeepLErrorMessage(status)`: Converts DeepL HTTP status codes into readable messages.
- `translateWithDeepL(selectedLanguage, sourceText)`: Sends the translation request.
- `handleTranslate()`: Validates input, starts loading, calls DeepL, updates output, and saves history.
- `handleCopy()`: Copies the translated result to the clipboard.
- `initializePanel()`: Restores saved draft text and history on load.

Storage keys used:

- `lingoDraftText`: Saved source text draft.
- `lingoTranslationHistory`: Saved recent translations.
- `lingoLastTargetLanguage`: Saved target language.

## `sidePanelServiceWorker.js`

This file is the background service worker configured by `manifest.json`.

It runs:

```js
chrome.sidePanel.setPanelBehavior({
    openPanelOnActionClick: true
}).catch(function(error) {
    console.log(error)
})
```

That tells Chrome to open the extension side panel when the user clicks the extension icon in the toolbar. If Chrome cannot set that behavior, the error is logged to the console.

## `logo(white).png`

This is the image used as the extension icon.

It is referenced in `manifest.json` for:

- `16` pixel icon.
- `32` pixel icon.
- `48` pixel icon.
- `128` pixel icon.
- Toolbar action icon.

Chrome can scale this image down, but separate optimized icon files would be better for a polished release.

## `README.md`

This is the main project guide.

It explains:

- What the extension does.
- The user-facing features.
- The tech used.
- The APIs used.
- The permissions.
- How the extension works.
- How to run it locally.
- Current user flow.
- Security notes.
- Future improvement ideas.

## `FILE_DOCUMENTATION.md`

This is the file you are reading now.

It explains:

- The purpose of each project file.
- The important IDs, functions, and constants.
- How the code is split between configuration, UI, styling, language loading, translation behavior, storage, and side panel behavior.

## How The Files Work Together

1. `manifest.json` tells Chrome this is a side panel extension and grants the needed permissions.
2. `sidePanelServiceWorker.js` makes the side panel open when the toolbar icon is clicked.
3. `panel.html` provides the UI shown in the side panel.
4. `styles.css` makes the UI readable and responsive.
5. `languageSelector.js` loads the target language dropdown and restores the saved target language.
6. `backendService.js` restores saved draft/history, handles translation, renders history, and manages copy/clear actions.
7. `logo(white).png` gives the extension its icon.
