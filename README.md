# Lingo - Language Translator

Lingo is a lightweight Chrome extension that opens a translator inside Chrome's side panel. It lets a user type or paste text, choose a target language, and translate the text through the DeepL Free API.

Link to the extension: https://chromewebstore.google.com/detail/lingo-language-translator/okfkakjgiocfbejhmlpfmlbgjgdkddbl

This README is the quick project guide: what the app does, what technology it uses, how to run it, and how someone could build a similar version themselves. For a detailed explanation of what every project file does, read [FILE_DOCUMENTATION.md](FILE_DOCUMENTATION.md).

## What The App Does

Lingo adds a translator panel to Chrome. When the extension icon is clicked, Chrome opens the side panel and shows a simple translation form.

The user flow is:

1. Open the extension from Chrome's toolbar.
2. Type or paste text into the input box.
3. Select a target language from the dropdown.
4. Click `Translate`.
5. Read the translated result in the output box.

Behind the scenes, the app loads target languages from DeepL, sends the user's text to DeepL, and displays the returned translation.

## Tech Used

- **Chrome Extension Manifest V3** for the extension configuration.
- **Chrome Side Panel API** to open the app inside Chrome's side panel.
- **HTML5** for the panel structure.
- **CSS3** for layout, colors, spacing, form styling, and responsive behavior.
- **Vanilla JavaScript** for DOM selection, events, API calls, and UI updates.
- **Browser Fetch API** for HTTP requests to DeepL.
- **DeepL Free API** for language lists and translations.

## Tools Used

- **Google Chrome** to run the extension.
- **Chrome Extensions page** at `chrome://extensions` to load the project as an unpacked extension.
- **Chrome DevTools** to inspect console logs, network requests, and API errors.
- **A code editor** such as VS Code to edit the files.
- **A DeepL API key** to call DeepL's API.

## APIs Used

The project currently uses the **DeepL Free API**.

### Load Target Languages

```text
GET https://api-free.deepl.com/v2/languages?type=target
```

This request loads the list of languages DeepL can translate into. The app turns that response into dropdown options.

### Translate Text

```text
POST https://api-free.deepl.com/v2/translate
```

This request sends the user's text and selected target language to DeepL. The app reads the translated result from:

```js
data.translations[0].text
```

There is also commented-out code for **LibreTranslate** in `backendService.js`. That older code points at:

```text
POST http://127.0.0.1:5000/translate
```

It is not active right now, but it shows how the project could be adapted to a local or self-hosted translation service.

## Packages

This project does **not** use npm packages.

There is no:

- `package.json`
- `node_modules`
- React
- Vite
- Express
- Bootstrap
- Tailwind
- build command

Chrome loads the files directly as an unpacked extension.

## Permissions

The extension requests this Chrome permission:

```json
["sidePanel"]
```

That allows the extension to use Chrome's side panel feature.

The extension also requests this host permission:

```json
["https://api-free.deepl.com/*"]
```

That allows browser requests to DeepL's Free API.

## Project Files

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

For a detailed explanation of each file, see [FILE_DOCUMENTATION.md](FILE_DOCUMENTATION.md).

## How The App Works

1. Chrome reads `manifest.json`.
2. Chrome registers `sidePanelServiceWorker.js` as the extension's background service worker.
3. The service worker tells Chrome to open the side panel when the extension icon is clicked.
4. Chrome loads `panel.html` inside the side panel.
5. `panel.html` loads `styles.css`, `languageSelector.js`, and `backendService.js`.
6. `languageSelector.js` calls DeepL's language endpoint and fills the dropdown.
7. The user enters text and clicks `Translate`.
8. `backendService.js` calls DeepL's translate endpoint.
9. DeepL returns the translated text.
10. The app displays the translation in the readonly output textarea.

## How To Run It Locally

1. Open Google Chrome.
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

### 1. Create The Extension Folder

Create a folder for the extension and add these files:

```text
manifest.json
panel.html
styles.css
languageSelector.js
backendService.js
sidePanelServiceWorker.js
logo.png
```

### 2. Configure The Extension

Create a `manifest.json` file with Manifest V3 settings:

```json
{
  "manifest_version": 3,
  "name": "My Translator",
  "version": "1.0",
  "description": "A simple side panel translator",
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

### 3. Build The Panel UI

In `panel.html`, create:

- A textarea for the text the user wants to translate.
- A select dropdown for the target language.
- A button that starts the translation.
- A readonly textarea for the translated result.

Load your scripts at the bottom of the body:

```html
<script src="languageSelector.js"></script>
<script src="backendService.js"></script>
```

### 4. Open The Side Panel From The Toolbar Icon

In `sidePanelServiceWorker.js`, use Chrome's Side Panel API:

```js
chrome.sidePanel.setPanelBehavior({
    openPanelOnActionClick: true
})
```

### 5. Load Languages From DeepL

In `languageSelector.js`, call DeepL's target languages endpoint:

```js
const response = await fetch("https://api-free.deepl.com/v2/languages?type=target", {
    method: "GET",
    headers: {
        "Authorization": "DeepL-Auth-Key YOUR_DEEPL_API_KEY"
    }
})
```

Then loop through the JSON response and add each language to the dropdown as an `<option>`.

### 6. Send Translation Requests

In `backendService.js`, call DeepL's translate endpoint when the user clicks the translate button:

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

Read the translated text from the response:

```js
const data = await response.json()
translationInput.value = data.translations[0].text
```

### 7. Handle Errors

Useful error handling includes:

- Empty input.
- Missing target language.
- DeepL usage limit errors.
- Rate limit errors.
- Network failures.
- Unexpected API responses.

### 8. Protect The API Key For Production

The current project calls DeepL directly from browser-side JavaScript. That means the API key is visible to anyone who opens the extension files or DevTools.

For a public version, a safer design is:

1. The Chrome extension sends text to your own backend.
2. The backend reads the DeepL key from an environment variable.
3. The backend calls DeepL.
4. The backend sends only the translated text back to the extension.

This keeps the API key private.

## Improvement Ideas

- Move the DeepL key to a backend server.
- Add validation before sending empty text.
- Disable the translate button while a request is loading.
- Add a copy-to-clipboard button.
- Add source language selection.
- Show DeepL's detected source language.
- Save the user's last selected target language with `chrome.storage`.
- Use separate optimized icon files for `16`, `32`, `48`, and `128` pixel sizes.
- Show visible error messages instead of only logging some failures to the console.
