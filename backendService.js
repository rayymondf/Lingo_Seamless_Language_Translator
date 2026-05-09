const textInput = document.getElementById("textInput")
const translationInput = document.getElementById("translationInput")
const translateBtn = document.getElementById("translateBtn")


//Following commented code is for LibreTranslate

// async function translation(){
//         const res = await fetch("http://127.0.0.1:5000/translate", {
//         method: "POST",
//         body: JSON.stringify({
//             q: textInput.value,
//             source: "en",
//             target: "fr",
//             format: "text"
//         }),
//         headers: { "Content-Type": "application/json" }
//     });

//     return await res.json()
// }

// translateBtn.addEventListener("click", async function(){
//     const data = await translation()
//     translationInput.value = data.translatedText
// })

async function testDeepL(selectedLanguage) {
    const response = await fetch("https://api-free.deepl.com/v2/translate", {
        method: "POST",
        headers: {
            "Authorization": "DeepL-Auth-Key _____________________________________________",
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            text: [textInput.value],
            target_lang: selectedLanguage
        })
    })

    const data = await response.json()
    if (response.status === 456) {
        translationInput.value = "testDeepL: DeepL API usage ran out"
    }
    else if (response.status === 429){
        translationInput.value = "testDeepL: Too many DeepL API requests"
    }
    else if (response.status === 500){
        translationInput.value = "testDeepL: DeepL internal server error"
    }
    else if (!response.ok || !data.translations || !data.translations[0]) {
        translationInput.value = "testDeepL: Translation Failed"
    }
    return data.translations[0].text
}


translateBtn.addEventListener("click", async function(){

 
    translationInput.value = "Translating..."
    try {
        translationInput.value = await testDeepL(targetLanguage.value)
        console.log(textInput.value + ` (to ${targetLanguage.value}) ` + translationInput.value)
    } catch (error) {
        translationInput.value = "addEventListener: Translation failed"
        //console.log(error)
    }
})
