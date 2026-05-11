const targetLanguageSelect = document.getElementById("targetLanguage")
const LAST_TARGET_LANGUAGE_KEY = "lingoLastTargetLanguage"
const DEEPL_AUTH_KEY = "306a351c-5e97-4478-aea9-ee268364fcda:fx"

window.lingoDeepLAuthKey = DEEPL_AUTH_KEY

const FALLBACK_LANGUAGES = [
    { language: "ES", name: "Spanish" },
    { language: "FR", name: "French" },
    { language: "DE", name: "German" },
    { language: "IT", name: "Italian" },
    { language: "JA", name: "Japanese" },
    { language: "KO", name: "Korean" },
    { language: "PT-BR", name: "Portuguese (Brazilian)" },
    { language: "ZH", name: "Chinese (generic)" }
]

function hasChromeStorage() {
    return typeof chrome !== "undefined" && chrome.storage && chrome.storage.local
}

function readLastTargetLanguage() {
    return new Promise(function(resolve) {
        if (hasChromeStorage()) {
            chrome.storage.local.get([LAST_TARGET_LANGUAGE_KEY], function(result) {
                resolve(result[LAST_TARGET_LANGUAGE_KEY])
            })
            return
        }

        try {
            resolve(JSON.parse(window.localStorage.getItem(LAST_TARGET_LANGUAGE_KEY)))
        } catch (error) {
            resolve(null)
        }
    })
}

function languageName(language) {
    if (language.language === "ZH") {
        return "Chinese (generic)"
    }
    return language.name
}

function populateLanguages(languages) {
    const languageOptions = languages.map(function(language) {
        const option = document.createElement("option")
        option.value = language.language
        option.textContent = languageName(language)
        return option
    })

    targetLanguageSelect.replaceChildren(...languageOptions)
}

async function loadLanguages() {
    let languages = FALLBACK_LANGUAGES

    try {
        const response = await fetch("https://api-free.deepl.com/v2/languages?type=target", {
            method: "GET",
            headers: {
                "Authorization": `DeepL-Auth-Key ${DEEPL_AUTH_KEY}`
            }
        })

        if (!response.ok) {
            throw new Error("Could not load languages")
        }

        languages = await response.json()
    } catch (error) {
        console.log(error)
    }

    populateLanguages(languages)

    const savedLanguage = await readLastTargetLanguage()
    if (savedLanguage && [...targetLanguageSelect.options].some(function(option) {
        return option.value === savedLanguage
    })) {
        targetLanguageSelect.value = savedLanguage
    }

    targetLanguageSelect.dispatchEvent(new Event("change"))
}

loadLanguages()
