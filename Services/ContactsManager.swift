import Foundation
import Contacts
import Combine

struct PhoneContactItem: Identifiable, Hashable {
    let id: String
    let name: String
    let phone: String
    let normalizedDigits: String
}

struct MatchedJuntoAccount: Hashable {
    let name: String
    let username: String
    let phone: String
    let proPlanType: ProPlanType
}

/// Gerenciador real da Agenda do iPhone (CNContactStore) com atualização em tempo real e verificação contra o PostgreSQL
@MainActor
final class ContactsManager: ObservableObject {
    static let shared = ContactsManager()

    @Published var phoneContacts: [PhoneContactItem] = []
    @Published var registeredByDigits: [String: MatchedJuntoAccount] = [:]
    @Published var authorizationStatus: CNAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    @Published var isLoading: Bool = false

    private let store = CNContactStore()
    private var changeObserver: AnyCancellable?

    private init() {
        // Atualiza automaticamente em tempo real sempre que a agenda do iPhone mudar
        changeObserver = NotificationCenter.default
            .publisher(for: .CNContactStoreDidChange)
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadContactsFromDevice()
            }
    }

    private func hasContactsAccess(_ status: CNAuthorizationStatus) -> Bool {
        if status == .authorized { return true }
        if #available(iOS 18.0, *), status == .limited { return true }
        return false
    }

    func requestAndLoadContacts() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        authorizationStatus = status

        if hasContactsAccess(status) {
            loadContactsFromDevice()
        } else if status == .notDetermined {
            store.requestAccess(for: .contacts) { [weak self] granted, _ in
                Task { @MainActor [weak self] in
                    self?.authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
                    if granted {
                        self?.loadContactsFromDevice()
                    }
                }
            }
        }
    }

    func loadContactsFromDevice() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        authorizationStatus = status
        guard hasContactsAccess(status) else { return }

        isLoading = true
        Task.detached(priority: .userInitiated) {
            let contactStore = CNContactStore()
            let keys: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor
            ]
            let request = CNContactFetchRequest(keysToFetch: keys)
            request.sortOrder = .givenName

            var loaded: [PhoneContactItem] = []
            var seenDigits = Set<String>()

            do {
                try contactStore.enumerateContacts(with: request) { contact, _ in
                    let fullName = [contact.givenName, contact.familyName]
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")

                    guard !fullName.isEmpty else { return }

                    for phoneEntry in contact.phoneNumbers {
                        let digits = Self.normalizeBrDigits(phoneEntry.value.stringValue)
                        guard digits.count >= 8, !seenDigits.contains(digits) else { continue }
                        seenDigits.insert(digits)

                        loaded.append(
                            PhoneContactItem(
                                id: "\(contact.identifier)_\(digits)",
                                name: fullName,
                                phone: Self.formatPhone(digits),
                                normalizedDigits: digits
                            )
                        )
                    }
                }
            } catch {
                // Silencioso caso o usuário revogue permissão
            }

            let sorted = loaded.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            await MainActor.run {
                self.phoneContacts = sorted
                self.isLoading = false
            }
            await self.syncRegisteredContactsWithServer(sorted)
        }
    }

    /// Verifica no PostgreSQL em tempo real quais contatos do iPhone realmente possuem conta no Juntô
    func syncRegisteredContactsWithServer(_ contacts: [PhoneContactItem]? = nil) async {
        let list = contacts ?? phoneContacts
        guard !list.isEmpty else { return }

        let payload = list.prefix(400).map { ["name": $0.name, "phone": $0.normalizedDigits] }
        let matched = await JuntoBackendService.shared.syncDeviceContacts(payload)

        var map: [String: MatchedJuntoAccount] = [:]
        for item in matched {
            guard let uname = item["username"] as? String,
                  let phone = item["phone"] as? String else { continue }
            let digits = Self.normalizeBrDigits(phone)
            let name = (item["name"] as? String) ?? uname
            let pType = ProPlanType(rawValue: (item["proPlanType"] as? String) ?? "none") ?? .none
            map[digits] = MatchedJuntoAccount(name: name, username: uname, phone: Self.formatPhone(digits), proPlanType: pType)
        }

        self.registeredByDigits = map
    }

    /// Salva um novo contato real na agenda do iPhone (CNContactStore) quando autorizado
    func saveContactToiPhone(name: String, phone: String) {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        guard hasContactsAccess(status) else { return }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ", maxSplits: 1)
        let newContact = CNMutableContact()
        newContact.givenName = parts.first.map(String.init) ?? trimmed
        if parts.count > 1 {
            newContact.familyName = String(parts[1])
        }
        newContact.phoneNumbers = [
            CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phone))
        ]

        let saveRequest = CNSaveRequest()
        saveRequest.add(newContact, toContainerWithIdentifier: nil)
        try? store.execute(saveRequest)
        loadContactsFromDevice()
    }

    func matchedAccount(for digits: String) -> MatchedJuntoAccount? {
        registeredByDigits[Self.normalizeBrDigits(digits)]
    }

    nonisolated static func normalizeBrDigits(_ raw: String) -> String {
        var digits = raw.filter { $0.isNumber }
        if digits.count >= 12 && digits.hasPrefix("55") {
            digits = String(digits.dropFirst(2))
        }
        return digits
    }

    nonisolated static func formatPhone(_ digits: String) -> String {
        let d = normalizeBrDigits(digits)
        if d.count == 11 {
            let ddd = d.prefix(2)
            let p1 = d.dropFirst(2).prefix(5)
            let p2 = d.suffix(4)
            return "(\(ddd)) \(p1)-\(p2)"
        } else if d.count == 10 {
            let ddd = d.prefix(2)
            let p1 = d.dropFirst(2).prefix(4)
            let p2 = d.suffix(4)
            return "(\(ddd)) \(p1)-\(p2)"
        }
        return d
    }

    static func inviteMessage(for name: String) -> String {
        let first = name.split(separator: " ").first.map(String.init) ?? name
        return "Oi \(first)! Estou usando o Juntô para organizar rolês, viagens e dividir contas sem estresse. Baixe o app por aqui: https://junto.app/baixar"
    }
}
