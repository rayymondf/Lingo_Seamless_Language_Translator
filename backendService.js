const textInput = document.getElementById("textInput")
const translationInput = document.getElementById("translationInput")
const translateBtn = document.getElementById("translateBtn")
const copyBtn = document.getElementById("copyBtn")
const targetLanguageInput = document.getElementById("targetLanguage")
const characterCount = document.getElementById("characterCount")
const statusMessage = document.getElementById("statusMessage")
const historyList = document.getElementById("historyList")
const emptyHistory = document.getElementById("emptyHistory")
const clearHistoryBtn = document.getElementById("clearHistoryBtn")

const MAX_HISTORY_ITEMS = 8
const STORAGE_KEYS = {
    draft: "lingoDraftText",
    history: "lingoTranslationHistory",
    targetLanguage: "lingoLastTargetLanguage"
}

let isTranslating = false
let translationHistory = []

function hasChromeStorage() {
    return typeof chrome !== "undefined" && chrome.storage && chrome.storage.local
}

function readStoredValue(key, fallbackValue) {
    return new Promise(function(resolve) {
        if (hasChromeStorage()) {
            chrome.storage.local.get([key], function(result) {
                resolve(result[key] ?? fallbackValue)
            })
            return
        }

        try {
            const savedValue = window.localStorage.getItem(key)
            resolve(savedValue ? JSON.parse(savedValue) : fallbackValue)
        } catch (error) {
            resolve(fallbackValue)
        }
    })
}

function writeStoredValue(key, value) {
    return new Promise(function(resolve) {
        if (hasChromeStorage()) {
            chrome.storage.local.set({ [key]: value }, resolve)
            return
        }

        try {
            window.localStorage.setItem(key, JSON.stringify(value))
        } catch (error) {
            console.log(error)
        }
        resolve()
    })
}

function setStatus(message, type) {
    statusMessage.textContent = message
    statusMessage.className = type ? `status status--${type}` : "status"
}

function updateCharacterCount() {
    const count = textInput.value.length
    characterCount.textContent = `${count} ${count === 1 ? "character" : "characters"}`
}

function updateControls() {
    const hasSourceText = textInput.value.trim().length > 0
    const hasTranslation = translationInput.value.trim().length > 0 && translationInput.value !== "Translating..."
    const hasTargetLanguage = targetLanguageInput.value.trim().length > 0

    translateBtn.disabled = isTranslating || !hasSourceText || !hasTargetLanguage
    copyBtn.disabled = !hasTranslation
}

function getSelectedLanguageLabel() {
    const selectedOption = targetLanguageInput.selectedOptions[0]
    return selectedOption ? selectedOption.textContent : targetLanguageInput.value
}

function formatHistoryDate(value) {
    return new Date(value).toLocaleString([], {
        month: "short",
        day: "numeric",
        hour: "numeric",
        minute: "2-digit"
    })
}

function renderHistory() {
    historyList.replaceChildren()
    emptyHistory.hidden = translationHistory.length > 0
    clearHistoryBtn.disabled = translationHistory.length === 0

    translationHistory.forEach(function(item) {
        const historyButton = document.createElement("button")
        historyButton.className = "history__item"
        historyButton.type = "button"
        historyButton.setAttribute("aria-label", `Reuse ${item.targetLabel} translation from history`)

        const meta = document.createElement("div")
        meta.className = "history__meta"

        const language = document.createElement("span")
        language.textContent = item.targetLabel

        const date = document.createElement("span")
        date.textContent = formatHistoryDate(item.createdAt)

        const sourceText = document.createElement("p")
        sourceText.className = "history__text"
        sourceText.textContent = item.sourceText

        const translatedText = document.createElement("p")
        translatedText.className = "history__text history__translation"
        translatedText.textContent = item.translatedText

        meta.append(language, date)
        historyButton.append(meta, sourceText, translatedText)
        historyButton.addEventListener("click", function() {
            textInput.value = item.sourceText
            translationInput.value = item.translatedText
            targetLanguageInput.value = item.targetLang
            writeStoredValue(STORAGE_KEYS.draft, item.sourceText)
            writeStoredValue(STORAGE_KEYS.targetLanguage, item.targetLang)
            updateCharacterCount()
            updateControls()
            setStatus("Loaded from history.", "success")
        })

        historyList.append(historyButton)
    })
}

async function saveToHistory(sourceText, translatedText) {
    const historyItem = {
        id: `${Date.now()}-${targetLanguageInput.value}`,
        sourceText,
        translatedText,
        targetLang: targetLanguageInput.value,
        targetLabel: getSelectedLanguageLabel(),
        createdAt: new Date().toISOString()
    }

    translationHistory = translationHistory.filter(function(item) {
        return item.sourceText !== sourceText || item.targetLang !== historyItem.targetLang
    })
    translationHistory.unshift(historyItem)
    translationHistory = translationHistory.slice(0, MAX_HISTORY_ITEMS)

    await writeStoredValue(STORAGE_KEYS.history, translationHistory)
    renderHistory()
}

function getDeepLErrorMessage(status) {
    if (status === 403) {
        return "DeepL rejected the API key."
    }
    if (status === 456) {
        return "DeepL API usage limit reached."
    }
    if (status === 429) {
        return "Too many DeepL requests. Try again shortly."
    }
    if (status >= 500) {
        return "DeepL is having trouble right now."
    }
    return "Translation failed. Please try again."
}

async function translateWithDeepL(selectedLanguage, sourceText) {
    if (!window.lingoDeepLAuthKey) {
        throw new Error("DeepL API key is missing.")
    }

    const response = await fetch("https://api-free.deepl.com/v2/translate", {
        method: "POST",
        headers: {
            "Authorization": `DeepL-Auth-Key ${window.lingoDeepLAuthKey}`,
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            text: [sourceText],
            target_lang: selectedLanguage
        })
    })

    let data = null
    try {
        data = await response.json()
    } catch (error) {
        data = null
    }

    const translatedText = data?.translations?.[0]?.text
    if (!response.ok) {
        throw new Error(getDeepLErrorMessage(response.status))
    }
    if (!translatedText) {
        throw new Error("DeepL returned an empty translation.")
    }

    return translatedText
}

async function handleTranslate() {
    const sourceText = textInput.value.trim()

    if (!sourceText) {
        setStatus("Add text before translating.", "error")
        updateControls()
        return
    }
    if (!targetLanguageInput.value) {
        setStatus("Choose a target language.", "error")
        updateControls()
        return
    }

    isTranslating = true
    translationInput.value = "Translating..."
    setStatus("Translating...")
    updateControls()

    try {
        const translatedText = await translateWithDeepL(targetLanguageInput.value, sourceText)
        translationInput.value = translatedText
        await saveToHistory(sourceText, translatedText)
        setStatus("Translation saved to recent history.", "success")
    } catch (error) {
        translationInput.value = ""
        setStatus(error.message, "error")
    } finally {
        isTranslating = false
        updateControls()
    }
}

async function handleCopy() {
    const translatedText = translationInput.value.trim()
    if (!translatedText) {
        return
    }

    try {
        await navigator.clipboard.writeText(translatedText)
        setStatus("Copied translation.", "success")
    } catch (error) {
        setStatus("Could not copy automatically.", "error")
    }
}

async function initializePanel() {
    const savedDraft = await readStoredValue(STORAGE_KEYS.draft, "")
    const savedHistory = await readStoredValue(STORAGE_KEYS.history, [])

    textInput.value = savedDraft
    translationHistory = Array.isArray(savedHistory) ? savedHistory : []

    renderHistory()
    updateCharacterCount()
    updateControls()
}

textInput.addEventListener("input", function() {
    writeStoredValue(STORAGE_KEYS.draft, textInput.value)
    updateCharacterCount()
    updateControls()
})

targetLanguageInput.addEventListener("change", function() {
    writeStoredValue(STORAGE_KEYS.targetLanguage, targetLanguageInput.value)
    updateControls()
})

translateBtn.addEventListener("click", handleTranslate)
copyBtn.addEventListener("click", handleCopy)
clearHistoryBtn.addEventListener("click", async function() {
    translationHistory = []
    await writeStoredValue(STORAGE_KEYS.history, translationHistory)
    renderHistory()
    setStatus("Recent history cleared.", "success")
})

initializePanel()
