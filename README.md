# 🎨 Emoji Generator (SwiftUI)

A playful **SwiftUI** app that turns short text prompts into expressive **emoji compositions** — a fun mix of creativity and code.  
Built to explore **SwiftUI animations**, **state management**, and **deterministic emoji generation** using a seeded random generator.

---

## ✨ Features
- 🧠 Type any short prompt (e.g., “happy sun party”) and generate a custom emoji cluster  
- 🎨 Adjustable background hues and randomized layouts  
- 📸 Save your emoji creation directly to Photos  
- 🪄 Copy the generated emoji sequence to clipboard  
- 🔁 Deterministic generation — same prompt + seed = same layout  

---

## 🧰 Tech Stack
- **SwiftUI** for reactive UI  
- **ImageRenderer** for offscreen image capture  
- **CoreGraphics** (via `ImageRenderer`) for high-resolution export  
- **UIKit** bridge (`UIImageWriteToSavedPhotosAlbum`) for Photos integration  

---

## 🚀 Getting Started

### 1️⃣ Clone the repo
```bash
git clone https://github.com/<your-username>/EmojiGenerator.git
cd EmojiGenerator
