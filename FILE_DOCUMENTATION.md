# Lingo File Documentation

This document explains what each file in the Lingo Chrome extension does. Use this when you want to understand the codebase file by file. For the general project overview, setup steps, tools, APIs, and implementation guide, read [README.md](README.md).

## File Map

```text
Lingo-Seamless_Language_Translator/
  .gitattributes
  backendService.js
  languageSelector.js
  logo(white).png
  manifest.json
  panel.html
  sidePanelServiceWorker.js
  styles.css
  README.md
  FILE_DOCUMENTATION.md
```

## `.gitattributes`

This file controls Git's line-ending behavior.

```text
* text=auto
```

That setting lets Git auto-detect text files and normalize line endings. It helps keep the project consistent when different people work on it across Windows, macOS, and Linux.

## `manifest.json`

This is the main Chrome extension configuration file. Chrome reads this file first to understand what the extension is, what permissions it needs, which files it should load, and how the toolbar action should behave.

Important fields:

- `manifest_version`: Uses Manifest V3, the modern Chrome extension format.
- `name`: Sets the extension name to `Lingo - Language Translator`.
- `version`: Sets the current extension version to `1.0`.
- `description`: Explains that the extension is a translator using the DeepL API.
- `permissions`: Requests the `sidePanel` permission.
- `host_permissions`: Allows requests to `https://api-free.deepl.com/*`.
- `icons`: Uses `logo(white).png` for the extension icons.
- `background.service_worker`: Points to `sidePanelServiceWorker.js`.
- `side_panel.default_path`: Tells Chrome to load `panel.html` in the side panel.
- `action.default_title`: Sets the toolbar hover/title text to `Open Lingo`.
- `action.default_icon`: Uses the logo for the toolbar icon.

Without this file, Chrome would not know how to load the extension.

## `panel.html`

This file defines the visible side panel interface.

It contains the page structure for:

- The app title: `Translate Cleanly`.
- The app intro text.
- The source text textarea.
- The target language dropdown.
- The `Translate` button.
- The readonly translation output textarea.

Important element IDs:

- `textInput`: Used by `backendService.js` to read the text the user wants translated.
- `targetLanguage`: Used by `languageSelector.js` to insert language options and by `backendService.js` to read the selected language.
- `translateBtn`: Used by `backendService.js` to attach the click event listener.
- `translationInput`: Used by `backendService.js` to show loading text, errors, and the final translation.

At the bottom, the file loads:

```html
<script src="languageSelector.js"></script>
<script src="backendService.js"></script>
```

The order matters. `languageSelector.js` creates the global `targetLanguage` constant first, and `backendService.js` later uses `targetLanguage.value` when translating.

## `styles.css`

This file styles the side panel.

Main responsibilities:

- Defines theme variables in `:root`.
- Sets global `box-sizing`.
- Styles the body background, font, spacing, and minimum height.
- Centers and sizes the main `.panel`.
- Styles the header, title, and intro text.
- Styles the `.card` container around the form.
- Styles form labels through `.field` and `.field__label`.
- Styles `textarea`, `select`, and `button` elements.
- Gives the output textarea a separate background through `#translationInput`.
- Adds focus states for textareas, selects, and the button.
- Adds hover styling to `#translateBtn`.

The CSS is standalone. It does not rely on Bootstrap, Tailwind, or any external stylesheet.

## `languageSelector.js`

This file loads DeepL's supported target languages and fills the target language dropdown.

It starts by selecting the dropdown:

```js
const targetLanguage = document.getElementById("targetLanguage")
```

Then it defines `loadLanguages()`, an async function that:

1. Calls DeepL's target languages endpoint.
2. Sends the DeepL API key in the `Authorization` header.
3. Throws an error if the response is not successful.
4. Parses the response JSON.
5. Loops through every returned language.
6. Creates an `<option>` for each language.
7. Sets the option value to the DeepL language code.
8. Sets the visible option text to the language name.
9. Renames DeepL's `ZH` option to `Chinese (generic)`.
10. Appends each option to the dropdown.

At the bottom, it calls:

```js
loadLanguages()
```

That means the language dropdown starts loading as soon as the side panel loads.

If the request fails, the current code logs the error to the console.

## `backendService.js`

This file handles translation behavior.

It starts by selecting key UI elements:

```js
const textInput = document.getElementById("textInput")
const translationInput = document.getElementById("translationInput")
const translateBtn = document.getElementById("translateBtn")
```

### Commented LibreTranslate Code

The first large comment block is an older or alternate LibreTranslate implementation.

It would call:

```text
http://127.0.0.1:5000/translate
```

That code is currently disabled. It shows how the project could use a local LibreTranslate server instead of DeepL.

### `testDeepL(selectedLanguage)`

This async function sends the actual DeepL translation request.

It calls:

```text
https://api-free.deepl.com/v2/translate
```

The request:

- Uses `POST`.
- Sends the DeepL API key in the `Authorization` header.
- Sends JSON with `Content-Type: application/json`.
- Sends the text as an array because DeepL expects `text` to be an array.
- Sends the selected target language as `target_lang`.

Request body shape:

```json
{
  "text": ["user text here"],
  "target_lang": "selected language code"
}
```

After the response comes back, the function parses JSON and checks for a few error cases:

- `456`: DeepL API usage ran out.
- `429`: Too many DeepL API requests.
- `500`: DeepL internal server error.
- Any failed or unexpected response: generic translation failure.

If the response is valid, it returns:

```js
data.translations[0].text
```

### Translate Button Listener

The file attaches a click listener to `translateBtn`.

When clicked, it:

1. Sets the output textarea to `Translating...`.
2. Calls `testDeepL(targetLanguage.value)`.
3. Places the returned translation in `translationInput.value`.
4. Logs the original text, target language, and translated text to the console.
5. Shows `addEventListener: Translation failed` if an exception occurs.

### Security Note

The current DeepL API key is written directly in frontend JavaScript. That means anyone with access to the extension files or Chrome DevTools can see it.

For a production app, this should be changed so the extension calls your own backend, and the backend calls DeepL with a private API key stored in an environment variable.

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

That tells Chrome to open the extension's side panel when the user clicks the extension icon in the toolbar.

If Chrome cannot set that behavior, the error is logged to the console.

## `logo(white).png`

This is the image used as the extension icon.

It is referenced in `manifest.json` for:

- `16` pixel icon.
- `32` pixel icon.
- `48` pixel icon.
- `128` pixel icon.
- Toolbar action icon.

Current source image details:

- PNG file.
- `1254 x 1254` pixels.

Chrome can scale this image down for the required icon sizes. For a more polished release, it would be better to create separate optimized icon files for each size.

## `README.md`

This is the main project guide.

It explains:

- What the app does.
- The tech used.
- The tools used.
- The APIs used.
- The packages or lack of packages.
- The permissions.
- How the app works.
- How to run it locally.
- How to implement a similar app yourself.
- Future improvement ideas.

## `FILE_DOCUMENTATION.md`

This is the file you are reading now.

It exists so the README can stay focused on project setup and implementation, while this file explains the role of each individual file in the codebase.

## How The Files Work Together

1. `manifest.json` tells Chrome this is a side panel extension.
2. `sidePanelServiceWorker.js` makes the side panel open when the toolbar icon is clicked.
3. `panel.html` provides the UI Chrome displays in the side panel.
4. `styles.css` makes that UI look polished and usable.
5. `languageSelector.js` fills the target language dropdown from DeepL.
6. `backendService.js` sends the user's text to DeepL and displays the translation.
7. `logo(white).png` gives the extension its icon.

