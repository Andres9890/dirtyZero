//
//  ContentView.swift
//  dirtyZero
//
//  Created by Skadz on 5/8/25.
//
// modfied by Andres99 on 5/11/25.

import SwiftUI
import DeviceKit
import notify

struct ZeroTweak: Identifiable, Codable {
    var id: String { name }
    var icon: String
    var name: String
    var paths: [String]
    
    enum CodingKeys: String, CodingKey {
        case icon, name, paths
    }
}

extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

var tweaks: [ZeroTweak] = [
    ZeroTweak(icon: "dock.rectangle", name: "Hide Dock", paths: ["/System/Library/PrivateFrameworks/CoreMaterial.framework/dockDark.materialrecipe", "/System/Library/PrivateFrameworks/CoreMaterial.framework/dockLight.materialrecipe"]),
    ZeroTweak(icon: "line.3.horizontal", name: "Hide Home Bar", paths: ["/System/Library/PrivateFrameworks/MaterialKit.framework/Assets.car"]),
    ZeroTweak(icon: "folder", name: "Hide Folder Backgrounds", paths: ["/System/Library/PrivateFrameworks/SpringBoardHome.framework/folderDark.materialrecipe", "/System/Library/PrivateFrameworks/SpringBoardHome.framework/folderLight.materialrecipe"]),
    ZeroTweak(icon: "bell.badge", name: "Hide Notification Backgrounds", paths: ["/System/Library/PrivateFrameworks/CoreMaterial.framework/platterStrokeLight.visualstyleset", "/System/Library/PrivateFrameworks/CoreMaterial.framework/platterStrokeDark.visualstyleset", "/System/Library/PrivateFrameworks/CoreMaterial.framework/plattersDark.materialrecipe", "/System/Library/PrivateFrameworks/CoreMaterial.framework/platters.materialrecipe"]),
    ZeroTweak(icon: "lock.iphone", name: "Hide Unlock Background", paths: ["/System/Library/PrivateFrameworks/CoverSheet.framework/dashBoardPasscodeBackground.materialrecipe"])
]

struct ContentView: View {
    let device = Device.current
    @AppStorage("enabledTweaks") private var enabledTweakIds: [String] = []
    @State private var makePermanent: Bool = false
    @State private var showingPermanentWarning: Bool = false
    
    private var enabledTweaks: [ZeroTweak] {
        tweaks.filter { tweak in enabledTweakIds.contains(tweak.id) }
    }
    
    private func isTweakEnabled(_ tweak: ZeroTweak) -> Bool {
        enabledTweakIds.contains(tweak.id)
    }
    
    private func toggleTweak(_ tweak: ZeroTweak) {
        if isTweakEnabled(tweak) {
            enabledTweakIds.removeAll { $0 == tweak.id }
        } else {
            enabledTweakIds.append(tweak.id)
        }
    }
    
    private func parseMultiplePaths(_ input: String) -> [String] {
        let paths = input.components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        if paths.count == 1 {
            return input.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        
        return paths
    }
    
    private func dirtyZeroHideMultiple(paths: [String]) {
        print("[*] Zeroing out \(paths.count) custom paths...")
        
        for (index, path) in paths.enumerated() {
            print("[\(index + 1)/\(paths.count)] Zeroing: \(path)")
            dirtyZeroHide(path: path, permanent: makePermanent)
        }
        
        print("[*] Successfully zeroed out all \(paths.count) paths!")
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section(header: HStack {
                        Image(systemName: "terminal.fill")
                        Text("Logs")
                    }) {
                        HStack {
                            Spacer()
                            ZStack {
                                LogView()
                                    .padding(3)
                                    .frame(width: 340, height: 260)
                            }
                            Spacer()
                        }
                        .onAppear(perform: {
                            print("[*] Welcome to dirtyZero!\n[*] Running on \(device.systemName!) \(device.systemVersion!), \(device.description)")
                        })
                    }
                    
                    Section(header: HStack {
                        Image(systemName: "hammer.fill")
                        Text("Tweaks")
                    }) {
                        VStack {
                            ForEach(tweaks) { tweak in
                                Button(action: {
                                    Haptic.shared.play(.soft)
                                    toggleTweak(tweak)
                                }) {
                                    HStack {
                                        Image(systemName: tweak.icon)
                                            .frame(width: 24, alignment: .center)
                                        Text(tweak.name)
                                            .lineLimit(1)
                                            .scaledToFit()
                                        Spacer()
                                        if isTweakEnabled(tweak) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.accent)
                                                .imageScale(.medium)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundStyle(.accent)
                                                .imageScale(.medium)
                                        }
                                    }
                                }
                                .buttonStyle(TintedButton(color: .accent, fullWidth: false))
                            }
                        }
                    }
                    
                    Section(header: HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Options")
                    }) {
                        Toggle(isOn: $makePermanent) {
                            HStack {
                                Image(systemName: "exclamationmark.shield.fill")
                                    .foregroundColor(.red)
                                Text("Make Changes Permanent (DANGEROUS)")
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                        .onChange(of: makePermanent) { newValue in
                            if newValue {
                                showingPermanentWarning = true
                            }
                        }
                    }
                    
                    Section(header: HStack {
                        Image(systemName: "gear")
                        Text("Actions")
                    }, footer: Text(makePermanent ? 
                        "⚠️ WARNING: Permanent changes cannot be reverted by reboot. This may cause system instability or bootloops. Use at your own risk!\n\nExploit discovered by Ian Beer of Google Project Zero. Created by the jailbreak.party team." :
                        "All tweaks are done in memory, so if something goes wrong, you can force reboot to revert changes.\n\nExploit discovered by Ian Beer of Google Project Zero. Created by the jailbreak.party team, modifed by Andres99."
                    )) {
                        Button(action: {
                            if makePermanent {
                                showingPermanentWarning = true
                            } else {
                                applyChanges()
                            }
                        }) {
                            HStack {
                                Image(systemName: makePermanent ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                    .foregroundColor(makePermanent ? .red : .primary)
                                Text(makePermanent ? "Apply Permanently" : "Apply")
                            }
                        }
                        .buttonStyle(TintedButton(color: enabledTweaks.isEmpty ? .accent.dark() : (makePermanent ? .red : .accent), fullWidth: true))
                        .contextMenu {
                            Button {
                                Alertinator.shared.prompt(title: "Enter custom path", placeholder: "/path/to/the/file/to/hide") { path in
                                    if let _ = path, !path!.isEmpty {
                                        dirtyZeroHide(path: path!, permanent: makePermanent)
                                    } else {
                                        Alertinator.shared.alert(title: "Invalid path", body: "Enter an actual path to what you want to hide/zero.")
                                    }
                                }
                            } label: {
                                Label("(Debug) Use custom file path", systemImage: "apple.terminal")
                            }
                            
                            Button {
                                let promptController = UIAlertController(title: "Enter multiple paths", message: nil, preferredStyle: .alert)
                                
                                promptController.addTextField { textView in
                                    textView.placeholder = "/path/to/the/file/to/hide, /path/to/the/file/to/hide"
                                    textView.text = ""
                                }
                                
                                promptController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                                
                                promptController.addAction(UIAlertAction(title: "Apply", style: .default) { _ in
                                    if let text = promptController.textFields?.first?.text, !text.isEmpty {
                                        let paths = parseMultiplePaths(text)
                                        
                                        if paths.isEmpty {
                                            Alertinator.shared.alert(title: "No valid paths", body: "Please enter at least one valid path")
                                        } else {
                                            let confirmController = UIAlertController(
                                                title: "Confirm paths",
                                                message: "About to zero out \(paths.count) files:\n\n\(paths.joined(separator: "\n"))",
                                                preferredStyle: .alert
                                            )
                                            
                                            confirmController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                                            confirmController.addAction(UIAlertAction(title: "Apply", style: .destructive) { _ in
                                                dirtyZeroHideMultiple(paths: paths)
                                            })
                                            
                                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                               let window = windowScene.windows.first,
                                               var topController = window.rootViewController {
                                                
                                                while let presentedViewController = topController.presentedViewController {
                                                    topController = presentedViewController
                                                }
                                                
                                                topController.present(confirmController, animated: true)
                                            }
                                        }
                                    } else {
                                        Alertinator.shared.alert(title: "Invalid input", body: "Please enter at least one valid path to zero out")
                                    }
                                })
                                
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first,
                                   var topController = window.rootViewController {
                                    
                                    while let presentedViewController = topController.presentedViewController {
                                        topController = presentedViewController
                                    }
                                    
                                    topController.present(promptController, animated: true)
                                }
                            } label: {
                                Label("(Debug) Zero multiple paths", systemImage: "doc.text.fill")
                            }
                        }
                        .disabled(enabledTweaks.isEmpty)
                    }
                }
            }
            .navigationTitle("dirtyZero")
            .alert("PERMANENT CHANGES WARNING", isPresented: $showingPermanentWarning) {
                Button("Cancel", role: .cancel) {
                    makePermanent = false
                }
                Button("I Understand the Risks", role: .destructive) {
                    if makePermanent {
                        applyChanges()
                    }
                }
            } message: {
                Text("""
                ⚠️ DANGER: Making changes permanent will directly modify system files on disk. These changes:
                
                • Cannot be reverted by rebooting
                • May cause system instability
                • Could result in bootloops
                • May require a full device restore to fix
                
                Only proceed if you fully understand the risks and have a backup of your device.
                """)
            }
        }
    }
    
    private func applyChanges() {
        var applyingString = "[*] Applying the selected tweaks"
        if makePermanent {
            applyingString += " PERMANENTLY"
        }
        applyingString += ": "
        let tweakNames = enabledTweaks.map { $0.name }.joined(separator: ", ")
        applyingString += tweakNames
        
        print(applyingString)
        
        for tweak in enabledTweaks {
            for path in tweak.paths {
                dirtyZeroHide(path: path, permanent: makePermanent)
            }
        }
        
        print("[*] All tweaks applied successfully!")
    }
    
    func dirtyZeroHide(path: String, permanent: Bool = false) {
    if permanent {
        print("[!] Making permanent changes to: \(path)")
        
        do {
            let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
            let zeroData = Data(count: 0x8000)
            fileHandle.write(zeroData)
            fileHandle.closeFile()
            print("[!] File permanently zeroed: \(path)")
        } catch {
            print("[!] Failed to make permanent changes to file \(path): \(error)")
            let args = ["permasign", path]
            var argv = args.map { strdup($0) }
            _ = permasign(Int32(args.count), &argv)
        }
    } else {
        let args = ["permasign", path]
        var argv = args.map { strdup($0) }
        
        _ = permasign(Int32(args.count), &argv)
    }
  }
}

// i skidded this stuff from cowabunga, sorry lemin.
struct MaterialView: UIViewRepresentable {
    let material: UIBlurEffect.Style

    init(_ material: UIBlurEffect.Style) {
        self.material = material
    }

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: material))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: material)
    }
}

struct TintedButton: ButtonStyle {
    var color: Color
    var material: UIBlurEffect.Style?
    var fullWidth: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            if fullWidth {
                configuration.label
                    .padding(15)
                    .frame(maxWidth: .infinity)
                    .background(material == nil ? AnyView(color.opacity(0.2)) : AnyView(MaterialView(material!)))
                    .cornerRadius(8)
                    .foregroundStyle(color)
            } else {
                configuration.label
                    .padding(15)
                    .frame(maxWidth: .infinity)
                    .background(material == nil ? AnyView(color.opacity(0.2)) : AnyView(MaterialView(material!)))
                    .cornerRadius(8)
                    .foregroundStyle(color)
            }
        }
    }
    
    init(color: Color = .blue, fullWidth: Bool = false) {
        self.color = color
        self.fullWidth = fullWidth
    }
    init(color: Color = .blue, material: UIBlurEffect.Style, fullWidth: Bool = false) {
        self.color = color
        self.material = material
        self.fullWidth = fullWidth
    }
}

#Preview {
    ContentView()
}
