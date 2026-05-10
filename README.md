# Lingo - Language Translator

Lingo is a lightweight Chrome extension that opens a translator inside Chrome's side panel. It uses plain HTML, CSS, and JavaScript to collect text from the user, load available target languages from DeepL, and send translation requests to the DeepL Free API.

## What It Uses

### Core Technologies

- **Chrome Extension Manifest V3** for extension setup, permissions, icons, background service worker, and side panel registration.
- **Chrome Side Panel API** so clicking the extension icon opens `panel.html` in Chrome's side panel.
- **Vanilla JavaScript** for DOM access, button events, API calls, and response handling.
- **HTML5** for the extension panel structure.
- **CSS3** for the responsive panel layout, form styling, gradients, focus states, and card UI.
- **Browser Fetch API** for calling DeepL endpoints from the extension.

### Tools Needed

- **Google Chrome** to load and run the extension.
- **Chrome Extensions page** at `chrome://extensions` to load the folder as an unpacked extension.
- **Chrome DevTools** for checking console messages, API errors, and network requests while debugging.
- **DeepL API account/key** for language loading and translation.
- **A code editor** such as VS Code for changing the HTML, CSS, JavaScript, and manifest files.

### APIs

The extension currently uses the **DeepL Free API**:

- `GET https://api-free.deepl.com/v2/languages?type=target`
  - Used by `languageSelector.js`.
  - Loads the list of languages DeepL can translate into.
  - Each response item is converted into an `<option>` inside the target language dropdown.

- `POST https://api-free.deepl.com/v2/translate`
  - Used by `backendService.js`.
  - Sends the user's text and selected target language to DeepL.
  - Reads `data.translations[0].text` from the response and places it in the output textarea.

There is also older commented-out code in `backendService.js` for **LibreTranslate**, using a local endpoint:

- `POST http://127.0.0.1:5000/translate`

That LibreTranslate code is not active right now, but it shows an alternate direction if you want to run translation through a local or self-hosted service.

### Packages

This project does **not** use npm packages, bundlers, frameworks, or build tools.

There is no `package.json`, no `node_modules`, and no install step. Chrome loads the files directly as an unpacked extension.

### Permissions

The extension requests:

- `sidePanel`
  - Allows the extension to use Chrome's side panel feature.

The extension also declares this host permission:

- `https://api-free.deepl.com/*`
  - Allows the extension to make requests to the DeepL Free API.

## File-by-File Overview

### `.gitattributes`

Configures Git to automatically detect text files and normalize line endings:

```text
* text=auto
```

This helps keep line endings consistent across Windows, macOS, and Linux.

### `manifest.json`

Defines the Chrome extension.

Important parts:

- `manifest_version: 3` tells Chrome this is a Manifest V3 extension.
- `name`, `version`, and `description` define the extension metadata.
- `permissions: ["sidePanel"]` enables side panel support.
- `host_permissions` allows requests to DeepL.
- `icons` points to `logo(white).png` for extension icons.
- `background.service_worker` registers `sidePanelServiceWorker.js`.
- `side_panel.default_path` tells Chrome to render `panel.html` in the side panel.
- `action.default_title` and `action.default_icon` configure the toolbar extension button.

### `panel.html`

Builds the side panel UI.

It contains:

- A title: `Translate Cleanly`
- A short intro line.
- A textarea for the original text.
- A dropdown for the target language.
- A `Translate` button.
- A readonly textarea for the translated result.

At the bottom, it loads:

```html
<script src="languageSelector.js"></script>
<script src="backendService.js"></script>
```

The order matters because `backendService.js` uses `targetLanguage`, which is created in `languageSelector.js`.

### `styles.css`

Controls the entire visual design of the side panel.

It includes:

- CSS variables for colors, shadows, borders, and focus rings.
- A responsive page background.
- The main panel layout.
- Header typography.
- Card styling.
- Form field spacing.
- Textarea, select, and button styling.
- Focus states for accessibility.
- A hover effect for the translate button.

The CSS is pure CSS and does not depend on Bootstrap, Tailwind, or any UI library.

### `languageSelector.js`

Loads DeepL target languages into the dropdown.

Main flow:

1. Finds the language dropdown with:

   ```js
   const targetLanguage = document.getElementById("targetLanguage")
   ```

2. Calls DeepL:

   ```js
   fetch("https://api-free.deepl.com/v2/languages?type=target", ...)
   ```

3. Converts each returned language into an `<option>`.

4. Special-cases DeepL's `ZH` language code so it appears as:

   ```text
   Chinese (generic)
   ```

5. Appends every option to the dropdown.

6. Calls `loadLanguages()` immediately when the script loads.

### `backendService.js`

Handles the actual translation button behavior.

Main pieces:

- Reads the input textarea, output textarea, and translate button from the DOM.
- Contains commented-out LibreTranslate code from an earlier or alternate implementation.
- Defines `testDeepL(selectedLanguage)`, which sends the translation request to DeepL.
- Sends this JSON body:

  ```json
  {
    "text": ["user text here"],
    "target_lang": "selected language code"
  }
  ```

- Handles specific DeepL error statuses:
  - `456`: API usage limit reached.
  - `429`: too many requests.
  - `500`: DeepL internal server error.
  - Other failed or unexpected responses: generic translation failure.

- Adds a click listener to the translate button.
- Shows `Translating...` while waiting for the API response.
- Places the translated text into the readonly output textarea.
- Logs the input, language, and translation to the console.

Important security note: the current implementation calls DeepL directly from browser-side JavaScript. That means the DeepL API key is visible to anyone who opens the extension files or DevTools. This is okay for a local learning project, but a production version should move DeepL requests behind a small backend server so the API key stays private.

### `sidePanelServiceWorker.js`

Configures how the side panel opens.

It calls:

```js
chrome.sidePanel.setPanelBehavior({
    openPanelOnActionClick: true
})
```

That makes the extension open the side panel when the user clicks the extension icon in Chrome's toolbar.

If Chrome throws an error, the service worker logs it to the console.

### `logo(white).png`

The extension icon image.

Current image details:

- PNG file.
- Used for `16`, `32`, `48`, and `128` icon sizes in `manifest.json`.
- Also used as the toolbar action icon.
- Source image size: `1254 x 1254`.

Chrome can scale it down for the listed icon sizes, though a polished extension may eventually use separate optimized icon files for each size.

## How The App Works

1. Chrome reads `manifest.json`.
2. Chrome registers `sidePanelServiceWorker.js` as the background service worker.
3. The service worker tells Chrome to open the side panel when the extension icon is clicked.
4. Chrome loads `panel.html` into the side panel.
5. `panel.html` loads `styles.css`, `languageSelector.js`, and `backendService.js`.
6. `languageSelector.js` calls DeepL's languages endpoint and fills the dropdown.
7. The user types text, chooses a target language, and clicks `Translate`.
8. `backendService.js` sends the text to DeepL's translate endpoint.
9. DeepL returns translated text.
10. The extension displays the translation in the output textarea.

## How To Run It Locally

1. Open Chrome.
2. Go to:

   ```text
   chrome://extensions
   ```

3. Turn on **Developer mode**.
4. Click **Load unpacked**.
5. Select this folder:

   ```text
   Lingo-Seamless_Language_Translator
   ```

6. Pin the extension if you want it visible in the toolbar.
7. Click the extension icon.
8. The Lingo side panel should open.

## How To Implement It Yourself

### 1. Create the project files

Create a folder with these files:

```text
manifest.json
panel.html
styles.css
languageSelector.js
backendService.js
sidePanelServiceWorker.js
logo.png
```

### 2. Add a Manifest V3 config

Your `manifest.json` needs:

- `manifest_version: 3`
- `permissions: ["sidePanel"]`
- `host_permissions` for the API you call.
- A background service worker.
- A `side_panel.default_path`.
- Extension action metadata.

Example structure:

```json
{
  "manifest_version": 3,
  "name": "My Translator",
  "version": "1.0",
  "permissions": ["sidePanel"],
  "host_permissions": ["https://api-free.deepl.com/*"],
  "background": {
    "service_worker": "sidePanelServiceWorker.js"
  },
  "side_panel": {
    "default_path": "panel.html"
  },
  "action": {
    "default_title": "Open Translator"
  }
}
```

### 3. Create the side panel UI

In `panel.html`, create:

- One textarea for source text.
- One select dropdown for target language.
- One button to start translation.
- One readonly textarea for the translated result.

Then load your JavaScript files at the bottom of the body.

### 4. Enable the side panel behavior

In `sidePanelServiceWorker.js`, call Chrome's Side Panel API:

```js
chrome.sidePanel.setPanelBehavior({
    openPanelOnActionClick: true
})
```

### 5. Load target languages

Use DeepL's languages endpoint:

```js
const response = await fetch("https://api-free.deepl.com/v2/languages?type=target", {
    method: "GET",
    headers: {
        "Authorization": "DeepL-Auth-Key YOUR_DEEPL_API_KEY"
    }
})
```

Then loop through the JSON response and add each language to the dropdown.

### 6. Translate user text

Use DeepL's translate endpoint:

```js
const response = await fetch("https://api-free.deepl.com/v2/translate", {
    method: "POST",
    headers: {
        "Authorization": "DeepL-Auth-Key YOUR_DEEPL_API_KEY",
        "Content-Type": "application/json"
    },
    body: JSON.stringify({
        text: [textInput.value],
        target_lang: targetLanguage.value
    })
})
```

Then read:

```js
const data = await response.json()
translationInput.value = data.translations[0].text
```

### 7. Add error handling

At minimum, handle:

- Empty input.
- Missing selected language.
- API usage limits.
- Rate limits.
- Network failures.
- Unexpected API responses.

### 8. Protect the API key for production

For a public or production release, do not keep the DeepL key in frontend JavaScript.

A safer setup is:

1. Chrome extension sends text to your own backend endpoint.
2. Backend reads the DeepL key from an environment variable.
3. Backend calls DeepL.
4. Backend returns only the translated text to the extension.

That way users can use the translator without seeing or copying the API key.

## Improvement Ideas

- Move the DeepL key to a backend server.
- Add an empty-input validation message before calling the API.
- Disable the translate button while a request is loading.
- Add a copy-to-clipboard button for the translated text.
- Add source language selection or auto-detect display.
- Save the user's last selected target language with `chrome.storage`.
- Replace the single large icon file with optimized `16`, `32`, `48`, and `128` pixel icons.
- Show visible error messages instead of only logging some failures to the console.
