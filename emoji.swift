import SwiftUI
import Photos

@main
struct EmojiGeneratorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Content

struct ContentView: View {
    @State private var prompt: String = ""
    @State private var seed: UInt64 = UInt64(Date().timeIntervalSince1970)
    @State private var bgHue: Double = 0.56
    @State private var showSavedAlert = false
    @State private var showErrorAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Controls
                VStack(spacing: 12) {
                    TextField("Describe a vibe (e.g., “happy sun party”)", text: $prompt)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)

                    HStack {
                        Button("Generate") { reseed() }
                            .buttonStyle(.borderedProminent)

                        Button("Randomize") { randomizeAll() }
                            .buttonStyle(.bordered)
                    }

                    HStack {
                        Text("Background")
                        Slider(value: $bgHue, in: 0...1)
                    }
                }
                .padding(.horizontal)

                // Canvas preview
                EmojiCanvas(prompt: prompt, seed: seed, bgHue: bgHue)
                    .frame(height: 360)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(radius: 6)
                    .padding(.horizontal)

                // Actions
                HStack {
                    Button {
                        saveCanvas()
                    } label: {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        UIPasteboard.general.string = EmojiComposer.emojis(from: prompt).joined()
                    } label: {
                        Label("Copy Emoji", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 4)

                Spacer(minLength: 8)
            }
            .navigationTitle("Emoji Generator")
            .alert("Saved!", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your emoji image was saved to Photos.")
            }
            .alert("Save Failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Couldn’t save the image. Check Photos permissions.")
            }
        }
    }

    private func reseed() {
        seed &+= 1
    }

    private func randomizeAll() {
        seed = UInt64.random(in: .min ... .max)
        bgHue = Double.random(in: 0...1)
        if prompt.isEmpty {
            // Add a playful auto-prompt
            let seeds = ["sparkles joy", "coffee code", "sun beach chill", "party confetti", "music vibe", "rocket innovate"]
            prompt = seeds.randomElement()!
        }
    }

    private func saveCanvas() {
        // Render the same view offscreen at a higher scale
        let renderer = ImageRenderer(content:
            EmojiCanvas(prompt: prompt, seed: seed, bgHue: bgHue)
                .frame(width: 1024, height: 1024)
        )
        renderer.scale = 2.0

        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            showSavedAlert = true
        } else {
            showErrorAlert = true
        }
    }
}

// MARK: - Canvas

struct EmojiCanvas: View {
    let prompt: String
    let seed: UInt64
    let bgHue: Double

    var body: some View {
        let emojis = EmojiComposer.emojis(from: prompt)
        let rng = SeededRandomGenerator(seed: seed)

        ZStack {
            // Soft gradient background
            LinearGradient(
                colors: [
                    Color(hue: bgHue, saturation: 0.35, brightness: 0.98),
                    Color(hue: (bgHue + 0.08).truncatingRemainder(dividingBy: 1.0), saturation: 0.45, brightness: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Emoji cluster
            GeometryReader { geo in
                let size = geo.size
                let count = max(6, min(14, emojis.count + 6))

                ForEach(0..<count, id: \.self) { i in
                    let e = emojis.randomElement(using: rng) ?? "✨"
                    let x = Double.random(in: 0.15...0.85, using: rng)
                    let y = Double.random(in: 0.15...0.85, using: rng)
                    let rot = Double.random(in: -10...10, using: rng)
                    let scale = Double.random(in: 0.8...1.4, using: rng)

                    Text(e)
                        .font(.system(size: min(size.width, size.height) * 0.12))
                        .rotationEffect(.degrees(rot))
                        .scaleEffect(scale)
                        .position(x: x * size.width, y: y * size.height)
                        .opacity(0.92)
                        .shadow(radius: 2)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.3), value: seed)
                }

                // Foreground “hero” emojis
                HStack(spacing: 8) {
                    ForEach(emojis.prefix(3), id: \.self) { e in
                        Text(e).font(.system(size: min(size.width, size.height) * 0.16))
                            .shadow(radius: 2)
                    }
                }
                .position(x: size.width * 0.5, y: size.height * 0.82)
            }
            .padding(12)

            // Title overlay
            VStack {
                Text(EmojiComposer.title(for: prompt))
                    .font(.system(size: 22, weight: .semibold))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 14)
                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Emoji Logic

enum EmojiComposer {
    private static let base: [String: [String]] = [
        "happy": ["😊","😄","😁","😸","✨","🤩"],
        "sun": ["🌞","☀️","😎","🌤️","🌈"],
        "party": ["🥳","🎉","🎊","🪩","🎈","🍰"],
        "coffee": ["☕️","🧋","🍪","💻","⌨️"],
        "music": ["🎵","🎧","🎶","🎸","🎹"],
        "code": ["👨‍💻","👩‍💻","💻","🧠","⚙️","🧩"],
        "love": ["❤️","💖","💕","💞","💘","😍"],
        "sparkles": ["✨","🌟","💫","⭐️"],
        "beach": ["🏖️","🌊","🕶️","🦀","🐚","🍹"],
        "space": ["🚀","🪐","🌌","👩‍🚀","🛰️"],
        "food": ["🍕","🍔","🍟","🍣","🌮","🍩","🍪"],
        "flower": ["🌸","🌼","🌻","🌷","🪻","💐"],
        "winter": ["❄️","☃️","🌨️","🧣","🧤","⛷️"],
        "fire": ["🔥","⚡️","💥","🚀","🏎️"],
        "calm": ["🌿","🧘","🍵","🌙","💤"]
    ]

    private static let fallback = ["✨","💫","🌟","⭐️","🎨","🧠","🚀","💡","🎉","😄"]

    static func emojis(from prompt: String) -> [String] {
        let tokens = prompt
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        var bag: [String] = []
        for t in tokens {
            if let matches = base[t] {
                bag.append(contentsOf: matches)
            }
        }
        if bag.isEmpty { bag = fallback }
        // Ensure some diversity
        return Array(bag.shuffled().prefix(10))
    }

    static func title(for prompt: String) -> String {
        let cleaned = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Generated Emoji Vibes" : cleaned.capitalized
    }
}

// MARK: - Seeded RNG

/// Minimal reproducible RNG so the same seed produces the same layout.
final class SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { self.state = seed &* 0x9E3779B97F4A7C15 }

    func next() -> UInt64 {
        // xorshift*
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// MARK: - Random helpers using a custom RNG

extension Double {
    static func random<T: RandomNumberGenerator>(in range: ClosedRange<Double>, using rng: T) -> Double {
        var g = rng
        let t = Double(g.next()) / Double(UInt64.max)
        return range.lowerBound + (range.upperBound - range.lowerBound) * t
    }
}

extension Array {
    func randomElement<T: RandomNumberGenerator>(using rng: T) -> Element? {
        var g = rng
        guard !isEmpty else { return nil }
        let idx = Int(g.next() % UInt64(count))
        return self[idx]
    }
}
