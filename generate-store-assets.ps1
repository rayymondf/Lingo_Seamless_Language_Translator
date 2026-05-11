Add-Type -AssemblyName System.Drawing

$OutDir = Join-Path $PSScriptRoot "store-assets"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function New-Canvas($Width, $Height) {
    $bitmap = New-Object System.Drawing.Bitmap($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    return @{ Bitmap = $bitmap; Graphics = $graphics }
}

function Color($Hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($Hex)
}

function Brush($Hex) {
    return New-Object System.Drawing.SolidBrush((Color $Hex))
}

function Pen($Hex, $Width = 1) {
    return New-Object System.Drawing.Pen((Color $Hex), $Width)
}

function Font($Size, $Style = [System.Drawing.FontStyle]::Regular) {
    return New-Object System.Drawing.Font("Segoe UI", $Size, $Style, [System.Drawing.GraphicsUnit]::Pixel)
}

function RoundedPath($X, $Y, $W, $H, $R) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $R * 2
    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $W - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc($X + $W - $diameter, $Y + $H - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($X, $Y + $H - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Fill-Rounded($G, $X, $Y, $W, $H, $R, $Fill, $Stroke = $null, $StrokeWidth = 1) {
    $path = RoundedPath $X $Y $W $H $R
    $G.FillPath((Brush $Fill), $path)
    if ($Stroke) {
        $G.DrawPath((Pen $Stroke $StrokeWidth), $path)
    }
    $path.Dispose()
}

function Draw-Text($G, $Text, $X, $Y, $W, $H, $Size, $Color, $Style = [System.Drawing.FontStyle]::Regular) {
    $font = Font $Size $Style
    $format = New-Object System.Drawing.StringFormat
    $format.Trimming = [System.Drawing.StringTrimming]::EllipsisWord
    $format.FormatFlags = 0
    $rect = New-Object System.Drawing.RectangleF($X, $Y, $W, $H)
    $G.DrawString($Text, $font, (Brush $Color), $rect, $format)
    $font.Dispose()
    $format.Dispose()
}

function Draw-Logo($G, $X, $Y, $Scale = 1) {
    $size = [int](38 * $Scale)
    Fill-Rounded $G $X $Y $size $size ([int](8 * $Scale)) "#246BFE"
    Draw-Text $G "A" ($X + 7 * $Scale) ($Y + 4 * $Scale) ($size - 6) ($size - 6) ([int](22 * $Scale)) "#FFFFFF" ([System.Drawing.FontStyle]::Bold)
    Draw-Text $G "z" ($X + 22 * $Scale) ($Y + 12 * $Scale) ($size - 12) ($size - 12) ([int](13 * $Scale)) "#FFFFFF" ([System.Drawing.FontStyle]::Bold)
}

function Draw-Brand($G, $X, $Y, $Scale = 1) {
    Draw-Logo $G $X $Y $Scale
    Draw-Text $G "Lingo" ($X + 48 * $Scale) ($Y + 5 * $Scale) (160 * $Scale) (38 * $Scale) ([int](22 * $Scale)) "#18212C" ([System.Drawing.FontStyle]::Bold)
}

function Draw-FeaturePills($G, $X, $Y, $Items, $Scale = 1) {
    $offset = 0
    foreach ($item in $Items) {
        $width = [int]((42 + ($item.Length * 8)) * $Scale)
        Fill-Rounded $G ($X + $offset) $Y $width ([int](34 * $Scale)) ([int](17 * $Scale)) "#EDF3FF" "#C9D8FF"
        Draw-Text $G $item ($X + $offset + 16 * $Scale) ($Y + 7 * $Scale) ($width - 20) ([int](22 * $Scale)) ([int](14 * $Scale)) "#246BFE" ([System.Drawing.FontStyle]::Bold)
        $offset += $width + [int](12 * $Scale)
    }
}

function Draw-BrowserMock($G, $X, $Y, $W, $H, $Mode = "search") {
    Fill-Rounded $G $X $Y $W $H 18 "#FFFFFF" "#D8DEE6" 2
    Fill-Rounded $G ($X + 1) ($Y + 1) ($W - 2) 54 18 "#F6F8FB"
    $G.FillEllipse((Brush "#EF6A5B"), $X + 24, $Y + 20, 12, 12)
    $G.FillEllipse((Brush "#F6C85F"), $X + 44, $Y + 20, 12, 12)
    $G.FillEllipse((Brush "#5CCB75"), $X + 64, $Y + 20, 12, 12)
    Fill-Rounded $G ($X + 100) ($Y + 16) ($W - 140) 24 12 "#FFFFFF" "#E2E8F0"

    if ($Mode -eq "article") {
        Draw-Text $G "The Future of Web Reading" ($X + 52) ($Y + 94) ($W - 104) 44 30 "#18212C" ([System.Drawing.FontStyle]::Bold)
        Fill-Rounded $G ($X + 52) ($Y + 156) ($W - 104) 112 10 "#DDEBFF"
        for ($i = 0; $i -lt 7; $i++) {
            $lineW = if ($i % 3 -eq 0) { $W - 150 } else { $W - 104 }
            Fill-Rounded $G ($X + 52) ($Y + 298 + $i * 30) $lineW 12 6 "#D9E1EA"
        }
    } elseif ($Mode -eq "docs") {
        Fill-Rounded $G ($X + 46) ($Y + 96) ($W - 92) 80 8 "#E7EEF8"
        for ($i = 0; $i -lt 6; $i++) {
            Fill-Rounded $G ($X + 70) ($Y + 210 + $i * 34) ($W - 140 - (($i % 2) * 70)) 14 7 "#D7DFEB"
        }
        Fill-Rounded $G ($X + 70) ($Y + 450) 150 34 17 "#246BFE"
        Draw-Text $G "Web page" ($X + 92) ($Y + 455) 130 24 16 "#FFFFFF" ([System.Drawing.FontStyle]::Bold)
    } else {
        Draw-Text $G "Google" ($X + 150) ($Y + 145) ($W - 300) 68 54 "#4285F4" ([System.Drawing.FontStyle]::Bold)
        Fill-Rounded $G ($X + 88) ($Y + 244) ($W - 176) 52 26 "#FFFFFF" "#CFD7E3"
        Draw-Text $G "Search in another language" ($X + 124) ($Y + 257) ($W - 248) 28 18 "#637083"
        Fill-Rounded $G ($X + 180) ($Y + 330) 130 38 19 "#F1F4F8" "#D8DEE6"
        Fill-Rounded $G ($X + 326) ($Y + 330) 150 38 19 "#F1F4F8" "#D8DEE6"
    }
}

function Draw-LingoPanel($G, $X, $Y, $W, $H, $WithHistory = $true, $Scale = 1) {
    Fill-Rounded $G $X $Y $W $H 18 "#FFFFFF" "#CCD6E2" 2
    Draw-Text $G "Translate Cleanly" ($X + 28 * $Scale) ($Y + 28 * $Scale) ($W - 56) (32 * $Scale) ([int](22 * $Scale)) "#18212C" ([System.Drawing.FontStyle]::Bold)
    Draw-Text $G "Easy-to-read translator for quick everyday use" ($X + 28 * $Scale) ($Y + 62 * $Scale) ($W - 56) (38 * $Scale) ([int](12 * $Scale)) "#637083"

    Draw-Text $G "Text to translate" ($X + 28 * $Scale) ($Y + 114 * $Scale) ($W - 56) (22 * $Scale) ([int](12 * $Scale)) "#18212C" ([System.Drawing.FontStyle]::Bold)
    Fill-Rounded $G ($X + 28 * $Scale) ($Y + 140 * $Scale) ($W - 56 * $Scale) (92 * $Scale) 8 "#FFFFFF" "#BDC7D2"
    Draw-Text $G "Hello, can you help me find the nearest train station?" ($X + 44 * $Scale) ($Y + 154 * $Scale) ($W - 88 * $Scale) (56 * $Scale) ([int](13 * $Scale)) "#637083"

    Draw-Text $G "Translate to" ($X + 28 * $Scale) ($Y + 250 * $Scale) ($W - 56) (22 * $Scale) ([int](12 * $Scale)) "#18212C" ([System.Drawing.FontStyle]::Bold)
    Fill-Rounded $G ($X + 28 * $Scale) ($Y + 276 * $Scale) ($W - 56 * $Scale) (38 * $Scale) 8 "#FFFFFF" "#BDC7D2"
    Draw-Text $G "French" ($X + 44 * $Scale) ($Y + 285 * $Scale) ($W - 88 * $Scale) (22 * $Scale) ([int](13 * $Scale)) "#18212C"

    Fill-Rounded $G ($X + 28 * $Scale) ($Y + 334 * $Scale) ($W - 118 * $Scale) (44 * $Scale) 8 "#246BFE"
    Draw-Text $G "Translate" ($X + 44 * $Scale) ($Y + 344 * $Scale) ($W - 150 * $Scale) (24 * $Scale) ([int](14 * $Scale)) "#FFFFFF" ([System.Drawing.FontStyle]::Bold)
    Fill-Rounded $G ($X + $W - 76 * $Scale) ($Y + 334 * $Scale) (48 * $Scale) (44 * $Scale) 8 "#FFFFFF" "#D8DEE6"
    Draw-Text $G "Copy" ($X + $W - 66 * $Scale) ($Y + 345 * $Scale) (40 * $Scale) (22 * $Scale) ([int](11 * $Scale)) "#18212C" ([System.Drawing.FontStyle]::Bold)

    Draw-Text $G "Translation" ($X + 28 * $Scale) ($Y + 400 * $Scale) ($W - 56) (22 * $Scale) ([int](12 * $Scale)) "#18212C" ([System.Drawing.FontStyle]::Bold)
    Fill-Rounded $G ($X + 28 * $Scale) ($Y + 426 * $Scale) ($W - 56 * $Scale) (88 * $Scale) 8 "#F2F6F5" "#BDC7D2"
    Draw-Text $G "Bonjour, pouvez-vous m'aider a trouver la gare la plus proche ?" ($X + 44 * $Scale) ($Y + 440 * $Scale) ($W - 88 * $Scale) (54 * $Scale) ([int](13 * $Scale)) "#14785D"

    if ($WithHistory) {
        Draw-Text $G "Recent translations" ($X + 28 * $Scale) ($Y + 548 * $Scale) ($W - 56) (24 * $Scale) ([int](14 * $Scale)) "#18212C" ([System.Drawing.FontStyle]::Bold)
        Fill-Rounded $G ($X + 28 * $Scale) ($Y + 580 * $Scale) ($W - 56 * $Scale) (58 * $Scale) 8 "#FBFCFE" "#D8DEE6"
        Draw-Text $G "French - Hello, can you help me..." ($X + 44 * $Scale) ($Y + 592 * $Scale) ($W - 88 * $Scale) (20 * $Scale) ([int](11 * $Scale)) "#637083"
        Draw-Text $G "Bonjour, pouvez-vous..." ($X + 44 * $Scale) ($Y + 614 * $Scale) ($W - 88 * $Scale) (20 * $Scale) ([int](11 * $Scale)) "#14785D"
    }
}

function Draw-Callout($G, $Text, $X, $Y, $W) {
    Fill-Rounded $G $X $Y $W 44 22 "#FFFFFF" "#C9D8FF"
    Draw-Text $G $Text ($X + 18) ($Y + 11) ($W - 36) 22 16 "#246BFE" ([System.Drawing.FontStyle]::Bold)
}

function Save-Png($Canvas, $Name) {
    $path = Join-Path $OutDir $Name
    $Canvas.Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $Canvas.Graphics.Dispose()
    $Canvas.Bitmap.Dispose()
}

function Draw-Screenshot($Name, $Title, $Subtitle, $Mode, $Layout) {
    $c = New-Canvas 1280 800
    $g = $c.Graphics
    $g.Clear((Color "#F4F8FF"))
    Fill-Rounded $g -80 590 520 260 130 "#E0ECFF"
    Fill-Rounded $g 950 -120 420 260 130 "#E5F0FF"
    Draw-Brand $g 78 72 1
    Draw-Text $g $Title 78 142 390 148 43 "#111827" ([System.Drawing.FontStyle]::Bold)
    Draw-Text $g $Subtitle 80 305 380 84 20 "#526174"
    Draw-FeaturePills $g 80 430 @("Side panel", "History", "Copy") 1

    if ($Layout -eq "article") {
        Draw-BrowserMock $g 485 92 430 610 "article"
        Draw-LingoPanel $g 890 120 300 560 $true 0.82
    } elseif ($Layout -eq "clarity") {
        Draw-LingoPanel $g 500 92 360 620 $true 0.95
        Draw-Callout $g "Saved history" 900 168 210
        Draw-Callout $g "Target language" 900 276 220
        Draw-Callout $g "Copy button" 900 386 190
        Draw-Callout $g "Readable output" 900 496 220
    } else {
        Draw-BrowserMock $g 480 112 455 520 $Mode
        Draw-LingoPanel $g 900 92 300 600 $true 0.83
    }

    Save-Png $c $Name
}

Draw-Screenshot "screenshot-1-translate-without-leaving-page.png" "Translate without leaving the page" "Open Lingo in Chrome's side panel and keep your browsing flow intact." "search" "default"
Draw-Screenshot "screenshot-2-three-simple-steps.png" "Translate in 3 simple steps" "Paste text, choose a language, and get a clean translation in seconds." "search" "default"
Draw-Screenshot "screenshot-3-keep-reading.png" "Keep reading while you translate" "Use the side panel beside articles, search results, docs, and everyday pages." "article" "article"
Draw-Screenshot "screenshot-4-designed-for-clarity.png" "Designed for clarity" "A focused interface with copy, saved history, and clear translation states." "search" "clarity"
Draw-Screenshot "screenshot-5-everyday-translation.png" "Helpful for everyday translation" "Useful for messages, study notes, travel phrases, and quick reading support." "docs" "default"

$small = New-Canvas 440 280
$g = $small.Graphics
$g.Clear((Color "#F4F8FF"))
Fill-Rounded $g -70 190 270 140 70 "#E0ECFF"
Draw-Brand $g 34 38 0.65
Draw-Text $g "Translate text" 34 86 190 42 26 "#111827" ([System.Drawing.FontStyle]::Bold)
Draw-Text $g "in Chrome's side panel" 35 124 185 30 15 "#526174"
Draw-LingoPanel $g 248 32 154 218 $false 0.43
Save-Png $small "small-promo-tile-440x280.png"

$marquee = New-Canvas 1400 560
$g = $marquee.Graphics
$g.Clear((Color "#F4F8FF"))
Fill-Rounded $g -120 382 520 240 120 "#E0ECFF"
Fill-Rounded $g 1080 -130 430 250 125 "#E4EFFF"
Draw-Brand $g 110 92 1.15
Draw-Text $g "Translate text while you browse" 110 165 470 128 50 "#111827" ([System.Drawing.FontStyle]::Bold)
Draw-Text $g "Translate without switching tabs. Copy results and revisit recent translations locally." 112 315 470 92 22 "#526174"
Draw-FeaturePills $g 112 420 @("Side panel", "Copy result", "Local history") 1
Draw-BrowserMock $g 660 68 440 430 "docs"
Draw-LingoPanel $g 1065 88 270 390 $false 0.74
Save-Png $marquee "marquee-promo-tile-1400x560.png"

Write-Host "Generated Chrome Web Store assets in $OutDir"
