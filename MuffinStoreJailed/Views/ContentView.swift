//
//  ContentView.swift
//  MuffinStoreJailed
//
//  Created by Mineek on 26/12/2024.
//

import SwiftUI
import PartyUI
import DeviceKit

struct ContentView: View {
    @State var ipaTool: IPATool?
    
    @State var appleId: String = ""
    @State var password: String = ""
    @State var code: String = ""
    
    @State var isAuthenticated: Bool = false
    @State var isDowngrading: Bool = false
    
    @State var appLink: String = ""
    
    @State var hasSent2FACode: Bool = false
    @State private var hasShownWelcome: Bool = false
    
    @State var showLogs: Bool = true
    @State var showPassword: Bool = false
    @State var showSettingsView: Bool = false
    
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        NavigationStack {
            List {
                if showLogs || weOnADebugBuild {
                    Section(header: ButtonLabel(text: "Logs", icon: "terminal")) {
                        VStack(alignment: .leading) {
                            HStack {
                                if appData.applicationIcon == "showMeProgressPlease" {
                                    ProgressView()
                                        .offset(y: 1)
                                } else {
                                    Image(systemName: appData.applicationIcon)
                                        .foregroundStyle(appData.applicationIconColor)
                                }
                                Text(appData.applicationStatus)
                                    .fontWeight(.semibold)
                            }
                            TerminalContainer(content: LogView())
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .modifier(DynamicGlassEffect(shape: AnyShape(.rect(cornerRadius: backgroundCornerRadius())), useBackground: false))
                        .listRowBackground(Color.clear)
                        .listRowInsets(.zeroInsets)
                    }
                }
                // login page view
                if !isAuthenticated {
                    Section(header: HeaderLabel(text: "Apple ID", icon: "icloud"), footer: Text("Created by [mineek](https://github.com/mineek/MuffinStoreJailed-Public), UI modifications done by lunginspector for [jailbreak.party](https://github.com/jailbreakdotparty). Use this tool at your own risk! App data may be lost, and other damage could occur.")) {
                        VStack(spacing: 12) {
                            TextField("Email Address", text: $appleId)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .textFieldStyle(GlassyTextFieldStyle(isDisabled: hasSent2FACode))
                            HStack {
                                if showPassword {
                                    TextField("Password", text: $password)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .textFieldStyle(GlassyTextFieldStyle(isDisabled: hasSent2FACode))
                                } else {
                                    SecureField("Password", text: $password)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .textFieldStyle(GlassyTextFieldStyle(isDisabled: hasSent2FACode))
                                }
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye" : "eye.slash")
                                        .frame(width: 20, height: 22)
                                }
                                .buttonStyle(GlassyButtonStyle())
                                .frame(width: 50)
                            }
                        }
                    }
                    if hasSent2FACode {
                        Section(header: HeaderLabel(text: "2FA Code", icon: "key"), footer: Text("If you did not receive a notification on any of the devices that are trusted to receive verification codes, type in six random numbers into the field. Trust me.")) {
                            TextField("2FA Code", text: $code)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .textFieldStyle(GlassyTextFieldStyle())
                        }
                    }
                } else {
                    // downgrading application view
                    if isDowngrading {
                        Section(header: HeaderLabel(text: "App Info", icon: "info.circle")) {
                            LabeledContent {
                                if appLink.isEmpty {
                                    ProgressView()
                                } else {
                                    Text(appLink)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "link")
                                        .frame(width: 24, alignment: .center)
                                    Text("App Store Link")
                                }
                            }
                            .contextMenu {
                                Button(action: {
                                    UIPasteboard.general.string = appLink
                                }) {
                                    Label("Copy Link", systemImage: "link")
                                }
                            }
                            LabeledContent {
                                if appData.appBundleID.isEmpty {
                                    ProgressView()
                                } else {
                                    Text(appData.appBundleID)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "shippingbox")
                                        .frame(width: 24, alignment: .center)
                                    Text("App Bundle ID")
                                }
                            }
                            LabeledContent {
                                if appData.appVersion.isEmpty {
                                    ProgressView()
                                } else {
                                    Text(appData.appVersion)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.down.app")
                                        .frame(width: 24, alignment: .center)
                                    Text("Target App Version")
                                }
                            }
                        }
                    } else {
                        // input the stupid app link or whatever view
                        Section(header: HeaderLabel(text: "Downgrade App", icon: "arrow.down.app"), footer: Text("Created by [mineek](https://github.com/mineek/MuffinStoreJailed-Public), UI modifications done by lunginspector for [jailbreak.party](https://github.com/jailbreakdotparty). Use this tool at your own risk! App data may be lost, and other damage could occur.")) {
                            HStack {
                                TextField("Link to App Store App", text: $appLink)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .textFieldStyle(GlassyTextFieldStyle())
                                Button(action: {
                                    Haptic.shared.play(.soft)
                                    appLink = UIPasteboard.general.string ?? ""
                                }) {
                                    Image(systemName: "doc.on.doc")
                                }
                                .buttonStyle(GlassyButtonStyle())
                                .frame(width: 50)
                            }
                        }
                    }
                }
            }
            .navigationTitle("PancakeStore")
            .safeAreaInset(edge: .bottom) {
                VStack {
                    // i hate this.
                    if !isAuthenticated {
                        Button(action: {
                            Haptic.shared.play(.soft)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                if appleId.isEmpty || password.isEmpty {
                                    Alertinator.shared.alert(title: "No Apple ID details were input!", body: "Please type both your Apple ID email address & password, then try again.")
                                } else {
                                    if code.isEmpty {
                                        ipaTool = IPATool(appleId: appleId, password: password)
                                        _ = ipaTool?.authenticate(requestCode: true, authCode: nil)
                                        hasSent2FACode = true
                                        return
                                    }
                                    
                                    ipaTool = IPATool(appleId: appleId, password: password)
                                    let ret = ipaTool?.authenticate(requestCode: false, authCode: code)
                                    
                                    isAuthenticated = ret ?? false
                                    
                                    if isAuthenticated {
                                        appData.applicationStatus = "Ready to Downgrade!"
                                        appData.applicationIcon = "checkmark.circle.fill"
                                        appData.applicationIconColor = .primary
                                    }
                                }
                            }
                        }) {
                            if hasSent2FACode {
                                ButtonLabel(text: "Log In", icon: "arrow.right")
                            } else {
                                ButtonLabel(text: "Send 2FA Code", icon: "key")
                            }
                        }
                        .buttonStyle(GlassyButtonStyle(isDisabled: hasSent2FACode ? code.isEmpty : false, isMaterialButton: true))
                    } else {
                        if isDowngrading {
                            Button(action: {
                                Haptic.shared.play(.soft)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    LSApplicationWorkspace.default().openApplication(withBundleID: "com.jbdotparty.PancakeStore2")
                                }
                            }) {
                                ButtonLabel(text: "Open App", icon: "arrow.up.forward.app")
                            }
                            .buttonStyle(GlassyButtonStyle(isDisabled: !appData.hasAppBeenServed, isMaterialButton: true))
                            Button(action: {
                                Haptic.shared.play(.heavy)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    exitinator()
                                }
                            }) {
                                ButtonLabel(text: "Go to Home Screen", icon: "house")
                            }
                            .buttonStyle(GlassyButtonStyle(isDisabled: !appData.hasAppBeenServed, color: .blue, isMaterialButton: true))
                        } else {
                            Button(action: {
                                Haptic.shared.play(.soft)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    if appLink.isEmpty {
                                        return
                                    }
                                    var appLinkParsed = appLink
                                    appLinkParsed = appLinkParsed.components(separatedBy: "id").last ?? ""
                                    for char in appLinkParsed {
                                        if !char.isNumber {
                                            appLinkParsed = String(appLinkParsed.prefix(upTo: appLinkParsed.firstIndex(of: char)!))
                                            break
                                        }
                                    }
                                    print("App ID: \(appLinkParsed)")
                                    isDowngrading = true
                                    downgradeApp(appId: appLinkParsed, ipaTool: ipaTool!)
                                    appData.applicationStatus = "Downgrading Application..."
                                    appData.applicationIcon = "showMeProgressPlease"
                                }
                            }) {
                                ButtonLabel(text: "Downgrade App", icon: "arrow.down")
                            }
                            .buttonStyle(GlassyButtonStyle(isMaterialButton: true))
                            
                            Button(action: {
                                Haptic.shared.play(.heavy)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    isAuthenticated = false
                                    EncryptedKeychainWrapper.nuke()
                                    EncryptedKeychainWrapper.generateAndStoreKey()
                                    sleep(3)
                                    exitinator()
                                }
                            }) {
                                ButtonLabel(text: "Log Out & Exit", icon: "xmark")
                            }
                            .buttonStyle(GlassyButtonStyle(color: .red, isMaterialButton: true))
                        }
                    }
                }
                .modifier(OverlayBackground())
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Haptic.shared.play(.soft)
                        showLogs.toggle()
                    }) {
                        Image(systemName: "terminal")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showSettingsView.toggle()
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettingsView) {
                SettingsView()
            }
            .onAppear {
                isAuthenticated = EncryptedKeychainWrapper.hasAuthInfo()
                print("Found \(isAuthenticated ? "auth" : "no auth") info in keychain")
                if isAuthenticated {
                    appData.applicationStatus = "Ready to Downgrade!"
                    appData.applicationIcon = "checkmark.circle.fill"
                    appData.applicationIconColor = .primary
                    guard let authInfo = EncryptedKeychainWrapper.getAuthInfo() else {
                        print("Failed to get auth info from keychain, logging out")
                        isAuthenticated = false
                        EncryptedKeychainWrapper.nuke()
                        EncryptedKeychainWrapper.generateAndStoreKey()
                        return
                    }
                    appleId = authInfo["appleId"]! as! String
                    password = authInfo["password"]! as! String
                    ipaTool = IPATool(appleId: appleId, password: password)
                    let ret = ipaTool?.authenticate()
                    print("Re-authenticated \(ret! ? "successfully" : "unsuccessfully")")
                } else {
                    print("No auth info found in keychain, setting up by generating a key in SEP")
                    EncryptedKeychainWrapper.generateAndStoreKey()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppData())
}
