import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .english:
            "English"
        case .spanish:
            "Español"
        }
    }

    var locale: Locale {
        switch self {
        case .english:
            Locale(identifier: "en")
        case .spanish:
            Locale(identifier: "es")
        }
    }

    func text(_ key: L10nKey) -> String {
        switch self {
        case .english:
            switch key {
            case .settingsTitle: "Settings"
            case .settingsSubtitle: "Store the GitHub username locally and the classic token securely in the iOS Keychain."
            case .githubUsername: "GitHub username"
            case .usernamePlaceholder: "perez987"
            case .usernameStoredHint: "This value is stored in UserDefaults and should match the account that owns the repositories you want to inspect."
            case .githubToken: "Classic private token"
            case .tokenStored: "Saved"
            case .tokenNotSaved: "Not saved"
            case .tokenStoredHint: "The token is stored only in the Keychain service \"github-release-downloads\" for the configured GitHub username, and is available only on this device."
            case .saveToken: "Save"
            case .deleteToken: "Delete"
            case .tokenSavedMessage: "Token saved securely in the Keychain."
            case .tokenDeletedMessage: "Token removed from the Keychain."
            case .languageSelectorTitle: "Language"
            case .languageSelectorSubtitle: "Choose the app language. The change is applied immediately."
            case .appLanguage: "App language"
            case .done: "Done"
            case .totalDownloadsAppTitle: "GitHub Total Downloads"
            case .totalDownloadsAppSubtitle: "Display the total number of downloads across all repositories."
            case .githubUser: "User"
            case .notSet: "Not set"
            case .tokenLabel: "Token"
            case .tokenOptional: "Not saved"
            case .repositories: "Repositories"
            case .withDownloads: "With Downloads"
            case .totalDownloads: "Total Downloads"
            case .runReport: "Run"
            case .running: "Running…"
            case .cancel: "Cancel"
            case .copy: "Copy"
            case .copiedMessage: "Output copied to the clipboard."
            case .clear: "Clear"
            case .settings: "Settings"
            case .reportSettingsHint: "Open Settings to enter the GitHub username before running the downloads report."
            case .reportPublicOnlyHint: ""
            case .liveOutput: "Live output"
            case .reportOutputEmpty: "Downloads by repository and the combined total will be displayed here."
            case .runStateReady: "Ready"
            case .runStateRunning: "Running"
            case .runStateCompleted: "Completed"
            case .runStateFailed: "Failed"
            case .runStateCancelled: "Cancelled"
            case .errorInvalidUsername: "Enter a GitHub username in Settings before starting."
            case .errorInvalidResponse: "GitHub returned an invalid response."
            case .errorServer: "GitHub API error (HTTP %d): %@"
            case .errorUnsuccessfulResponse: "GitHub returned an unsuccessful response."
            case .errorEmptyUsernameForKeychain: "Enter a GitHub username before saving a token to the Keychain."
            case .errorEmptyTokenForKeychain: "Enter a GitHub token before saving it to the Keychain."
            case .errorKeychainStatus: "Keychain error %d."
            case .logUser: "User: %@"
            case .logQueryingReleaseDownloads: "Querying repositories..."
            case .logNoRepositoriesFound: "No repositories were found."
            case .logRepositoriesAnalyzed: "Repositories analyzed: %d"
            case .logRepositoriesWithDownloads: "Repositories with downloads: %d"
            case .logRunCancelled: "Run cancelled"
            case .downloadsTableRepositoryHeader: "REPOSITORY"
            case .downloadsTableDownloadsHeader: "DOWNLOADS"
            }
        case .spanish:
            switch key {
            case .settingsTitle: "Configuración"
            case .settingsSubtitle: "Guarda el usuario de GitHub localmente y el token clásico de forma segura en el llavero de iOS."
            case .githubUsername: "Usuario de GitHub"
            case .usernamePlaceholder: "perez987"
            case .usernameStoredHint: "Este valor se guarda en UserDefaults y debe coincidir con la cuenta propietaria de los repositorios que quieres inspeccionar."
            case .githubToken: "Token clásico privado"
            case .tokenStored: "Guardado"
            case .tokenNotSaved: "No guardado"
            case .tokenStoredHint: "El token se guarda solamente en el servicio del llavero \"github-release-downloads\" para el usuario de GitHub configurado, y solo está disponible en este dispositivo."
            case .saveToken: "Guardar"
            case .deleteToken: "Eliminar"
            case .tokenSavedMessage: "Token guardado de forma segura en el llavero."
            case .tokenDeletedMessage: "Token eliminado del llavero."
            case .languageSelectorTitle: "Idioma"
            case .languageSelectorSubtitle: "Elige el idioma de la app. El cambio se aplica de inmediato."
            case .appLanguage: "Idioma de la app"
            case .done: "Hecho"
            case .totalDownloadsAppTitle: "Descargas Totales de GitHub"
            case .totalDownloadsAppSubtitle: "Muestra el número total de descargas en todos los repositorios."
            case .githubUser: "Usuario"
            case .notSet: "Sin definir"
            case .tokenLabel: "Token"
            case .tokenOptional: "No guardado"
            case .repositories: "Repositorios"
            case .withDownloads: "Con descargas"
            case .totalDownloads: "Descargas totales"
            case .runReport: "Ejecutar"
            case .running: "Ejecutando…"
            case .cancel: "Cancelar"
            case .copy: "Copiar"
            case .copiedMessage: "Salida copiada al portapapeles."
            case .clear: "Limpiar"
            case .settings: "Configuración"
            case .reportSettingsHint: "Abre Configuración para ingresar el usuario de GitHub antes de ejecutar el informe de descargas."
            case .reportPublicOnlyHint: ""
            case .liveOutput: "Salida en vivo"
            case .reportOutputEmpty: "Aquí se mostrarán las descargas por repositorio y la suma total."
            case .runStateReady: "Listo"
            case .runStateRunning: "Ejecutando"
            case .runStateCompleted: "Completado"
            case .runStateFailed: "Falló"
            case .runStateCancelled: "Cancelado"
            case .errorInvalidUsername: "Introduce un usuario de GitHub en Configuración antes de comenzar."
            case .errorInvalidResponse: "GitHub devolvió una respuesta no válida."
            case .errorServer: "Error de la API de GitHub (HTTP %d): %@"
            case .errorUnsuccessfulResponse: "GitHub devolvió una respuesta fallida."
            case .errorEmptyUsernameForKeychain: "Ingresa un usuario de GitHub antes de guardar un token en el llavero."
            case .errorEmptyTokenForKeychain: "Ingresa un token de GitHub antes de guardarlo en el llavero."
            case .errorKeychainStatus: "Error del llavero %d."
            case .logUser: "Usuario: %@"
            case .logQueryingReleaseDownloads: "Consultando repositorios..."
            case .logNoRepositoriesFound: "No se encontraron repositorios."
            case .logRepositoriesAnalyzed: "Repositorios analizados: %d"
            case .logRepositoriesWithDownloads: "Repositorios con descargas: %d"
            case .logRunCancelled: "Ejecución cancelada"
            case .downloadsTableRepositoryHeader: "REPOSITORIO"
            case .downloadsTableDownloadsHeader: "DESCARGAS"
            }
        }
    }

    func formatted(_ key: L10nKey, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: locale, arguments: arguments)
    }

    func errorMessage(for error: Error) -> String {
        if let error = error as? GitHubAPIError {
            return error.errorDescription(in: self)
        }

        if let error = error as? KeychainTokenStoreError {
            return error.errorDescription(in: self)
        }

        return error.localizedDescription
    }
}

enum L10nKey {
    case settingsTitle
    case settingsSubtitle
    case githubUsername
    case usernamePlaceholder
    case usernameStoredHint
    case githubToken
    case tokenStored
    case tokenNotSaved
    case tokenStoredHint
    case saveToken
    case deleteToken
    case tokenSavedMessage
    case tokenDeletedMessage
    case languageSelectorTitle
    case languageSelectorSubtitle
    case appLanguage
    case done
    case totalDownloadsAppTitle
    case totalDownloadsAppSubtitle
    case githubUser
    case notSet
    case tokenLabel
    case tokenOptional
    case repositories
    case withDownloads
    case totalDownloads
    case runReport
    case running
    case cancel
    case copy
    case copiedMessage
    case clear
    case settings
    case reportSettingsHint
    case reportPublicOnlyHint
    case liveOutput
    case reportOutputEmpty
    case runStateReady
    case runStateRunning
    case runStateCompleted
    case runStateFailed
    case runStateCancelled
    case errorInvalidUsername
    case errorInvalidResponse
    case errorServer
    case errorUnsuccessfulResponse
    case errorEmptyUsernameForKeychain
    case errorEmptyTokenForKeychain
    case errorKeychainStatus
    case logUser
    case logQueryingReleaseDownloads
    case logNoRepositoriesFound
    case logRepositoriesAnalyzed
    case logRepositoriesWithDownloads
    case logRunCancelled
    case downloadsTableRepositoryHeader
    case downloadsTableDownloadsHeader
}

@MainActor
final class SettingsStore: ObservableObject {
    private enum Keys {
        static let username = "githubUsername"
        static let language = "appLanguage"
    }

    @Published var githubUsername: String {
        didSet {
            UserDefaults.standard.set(githubUsername, forKey: Keys.username)
            refreshStoredTokenState()
        }
    }

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Keys.language)
        }
    }

    @Published private(set) var hasStoredToken: Bool

    private let keychain = KeychainTokenStore()

    init() {
        let storedUsername = UserDefaults.standard.string(forKey: Keys.username) ?? ""
        githubUsername = storedUsername
        language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: Keys.language) ?? "") ?? .english
        hasStoredToken = keychain.hasToken(for: Self.trimmed(storedUsername))
    }

    func trimmedUsername() -> String {
        Self.trimmed(githubUsername)
    }

    func loadToken() -> String? {
        try? keychain.readToken(for: trimmedUsername())
    }

    func saveToken(_ token: String) throws {
        try keychain.saveToken(token, for: trimmedUsername())
        hasStoredToken = true
    }

    func deleteToken() throws {
        try keychain.deleteToken(for: trimmedUsername())
        hasStoredToken = false
    }

    func text(_ key: L10nKey) -> String {
        language.text(key)
    }

    func formatted(_ key: L10nKey, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: language.locale, arguments: arguments)
    }

    func message(for error: Error) -> String {
        language.errorMessage(for: error)
    }

    private func refreshStoredTokenState() {
        hasStoredToken = keychain.hasToken(for: trimmedUsername())
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
