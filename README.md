# Lingo - Language Translator

Lingo is a lightweight Chrome extension that opens a translator inside Chrome's side panel. A user can type or paste text, choose a target language, translate through the DeepL Free API, copy the result, and reuse recent translations saved locally in the browser.

Chrome Web Store link: https://chromewebstore.google.com/detail/lingo-language-translator/okfkakjgiocfbejhmlpfmlbgjgdkddbl

This README is the main project guide. It explains what the extension does, how it works, how to run it locally, and what could be improved next. For a file-by-file explanation, read [FILE_DOCUMENTATION.md](FILE_DOCUMENTATION.md).

## What The Extension Does

Lingo adds a translation workspace to Chrome's side panel. When the extension icon is clicked, Chrome opens the side panel and shows a simple translator UI.

The user can:

- Type or paste text to translate.
- See a live character count.
- Choose a target language.
- Translate text with DeepL.
- Copy the translated result.
- See clear loading, success, and error messages.
- Reopen recent translations from browser-local history.
- Clear recent translation history.
- Keep draft text and the last selected language between side panel sessions.

Recent history, draft text, and the last selected language are stored locally through Chrome storage. They are not sent anywhere except when text is translated through DeepL.

## Tech Used

- **Chrome Extension Manifest V3** for extension configuration.
- **Chrome Side Panel API** to open the translator in Chrome's side panel.
- **Chrome Storage API** to save draft text, recent translations, and the last target language locally.
- **HTML5** for the panel structure.
- **CSS3** for responsive layout and visual styling.
- **Vanilla JavaScript** for UI behavior, browser storage, and API requests.
- **Fetch API** for HTTP requests.
- **DeepL Free API** for language lists and translation.
- **LibreTranslate** as an optional local/self-hosted translation alternative.

## Packages

This project does not use npm packages.

There is no:

- `package.json`
- `node_modules`
- React
- Vite
- Express
- Tailwind
- Build command

Chrome loads the files directly as an unpacked extension.

## APIs Used

### DeepL Target Languages

```text
GET https://api-free.deepl.com/v2/languages?type=target
```

This request loads the target languages supported by DeepL. If this request fails, the extension uses a small built-in fallback language list so the dropdown is still usable.

### DeepL Translate

```text
POST https://api-free.deepl.com/v2/translate
```

This request sends the user's text and selected target language to DeepL. The translated result is read from:

```js
data.translations[0].text
```

### Optional Local LibreTranslate

The extension can also be adapted to use a locally hosted translation server instead of DeepL. The earlier version of this project had commented LibreTranslate code in `backendService.js`; that code was removed during cleanup, but the idea is still valid.

LibreTranslate can run on your own machine, commonly at:

```text
http://127.0.0.1:5000/translate
```

With LibreTranslate, the request body usually looks like:

```json
{
  "q": "Text to translate",
  "source": "en",
  "target": "fr",
  "format": "text"
}
```

The response usually returns the translated result as:

```js
data.translatedText
```

Using LibreTranslate locally can be helpful because:

- You can test without using DeepL quota.
- You can avoid exposing a DeepL API key in frontend code.
- You can experiment with a self-hosted translation service.

To fully switch this extension to LibreTranslate, `backendService.js` would need to call the local LibreTranslate endpoint instead of DeepL, and `manifest.json` would need permission for the local host URL.

## Permissions

The extension requests:

```json
["sidePanel", "storage"]
```

- `sidePanel` lets the extension open inside Chrome's side panel.
- `storage` lets the extension save local draft text, recent translations, and the last target language.

The extension also requests this host permission:

```json
["https://api-free.deepl.com/*"]
```

That allows the extension to call DeepL's Free API.

If you switch to local LibreTranslate, you would also need a host permission like:

```json
["http://127.0.0.1:5000/*"]
```

## Project Files

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

## How The Extension Works

1. Chrome reads `manifest.json`.
2. Chrome registers `sidePanelServiceWorker.js` as the background service worker.
3. The service worker tells Chrome to open the side panel when the extension icon is clicked.
4. Chrome loads `panel.html` inside the side panel.
5. `panel.html` loads `styles.css`, `languageSelector.js`, and `backendService.js`.
6. `languageSelector.js` loads DeepL target languages, falls back if needed, and restores the user's last selected language.
7. `backendService.js` restores saved draft text and local translation history.
8. The user enters text, chooses a language, and clicks `Translate`.
9. `backendService.js` sends the text to DeepL and displays the returned translation.
10. The extension saves the successful translation to recent local history.

## How To Run It Locally

1. Open Google Chrome.
2. Go to:

   ```text
   chrome://extensions
   ```

3. Turn on **Developer mode**.
4. Click **Load unpacked**.
5. Select this project folder:

   ```text
   Lingo-Seamless_Language_Translator
   ```

6. Pin the extension if you want it visible in the toolbar.
7. Click the extension icon.
8. The Lingo side panel should open.

After code changes, go back to `chrome://extensions` and click the reload button for the extension.

## Current User Flow

1. Open Lingo from Chrome's toolbar.
2. Type or paste text into the input box.
3. Pick a target language.
4. Click `Translate`.
5. Wait for the loading message to finish.
6. Copy the result if needed.
7. Click a recent translation to reload it later.
8. Use `Clear` to remove saved recent translations.

## Production Security Note

The current project calls DeepL directly from browser-side JavaScript. That means the API key is visible to anyone who opens the extension files or DevTools.

For a production version, a safer DeepL design is:

1. The Chrome extension sends text to your own backend.
2. The backend reads the DeepL key from an environment variable.
3. The backend calls DeepL.
4. The backend sends only the translated text back to the extension.

This keeps the API key private and gives you more control over rate limits, abuse prevention, and logging.

A local LibreTranslate setup is another option for development or private use. In that setup, your extension sends translation requests to a local server running on your computer instead of sending them directly to DeepL.

## Improvement Ideas

- Move the DeepL API key to a backend service before a public production release.
- Add a setting to choose between DeepL and a local LibreTranslate server.
- Add source language selection or show DeepL's detected source language.
- Add a button to swap source and target languages if source language support is added.
- Add a "favorite" option for important translations.
- Add delete buttons for individual history items.
- Add keyboard shortcuts, such as `Ctrl + Enter` to translate.
- Create separate optimized icon files for `16`, `32`, `48`, and `128` pixel sizes.
