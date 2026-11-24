import Foundation
import Contacts

struct PhoneContactItem: Identifiable, Hashable {
    let id: String
    let name: String
    let phone: String
    let normalizedDigits: String
}

/// Gerenciador nativo da Agenda de Contatos do iPhone (CNContactStore), estilo WhatsApp
@MainActor
final class ContactsManager: ObservableObject {
    static let shared = ContactsManager()

    @Published var phoneContacts: [PhoneContactItem] = []
    @Published var authorizationStatus: CNAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    @Published var isLoading: Bool = false

    private let store = CNContactStore()

    private init() {}

    func requestAndLoadContacts() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        authorizationStatus = status

        switch status {
        case .authorized, .limited:
            loadContactsFromDevice()
        case .notDetermined:
            store.requestAccess(for: .contacts) { [weak self] granted, _ in
                Task { @MainActor [weak self] in
                    self?.authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
                    if granted {
                        self?.loadContactsFromDevice()
                    }
                }
            }
        default:
            break
        }
    }

    func loadContactsFromDevice() {
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

                    guard !fullName.isEmpty, let firstPhone = contact.phoneNumbers.first?.value.stringValue else {
                        return
                    }

                    let digits = Self.normalizeBrDigits(firstPhone)
                    guard digits.count >= 8, !seenDigits.contains(digits) else { return }
                    seenDigits.insert(digits)

                    loaded.append(
                        PhoneContactItem(
                            id: contact.identifier,
                            name: fullName,
                            phone: Self.formatPhone(digits),
                            normalizedDigits: digits
                        )
                    )
                }
            } catch {
                // Silencioso caso o usuário não autorize a agenda
            }

            let sorted = loaded.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            await MainActor.run {
                self.phoneContacts = sorted
                self.isLoading = false
            }
        }
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
}
