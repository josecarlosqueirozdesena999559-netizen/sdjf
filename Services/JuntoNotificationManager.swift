import Foundation
import UserNotifications
import SwiftUI

/// Sistema Real de Notificações do Aplicativo (UNUserNotificationCenter do iOS + Banners em foreground + Som + Badge)
@MainActor
final class JuntoNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = JuntoNotificationManager()

    @Published var isAuthorized: Bool = false
    @Published var apnsDeviceToken: String? = nil

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Solicita permissão real de notificações do iOS e configura categorias interativas
    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT_FRIEND",
            title: "Aceitar convite",
            options: [.foreground]
        )
        let friendCategory = UNNotificationCategory(
            identifier: "JUNTO_FRIEND_INVITE",
            actions: [acceptAction],
            intentIdentifiers: [],
            options: []
        )
        let paymentCategory = UNNotificationCategory(
            identifier: "JUNTO_PAYMENT",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([friendCategory, paymentCategory])

        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            Task { @MainActor in
                self.isAuthorized = granted
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    /// Dispara uma notificação nativa real do iOS imediatamente (aparece no topo do iPhone mesmo com o app aberto)
    func triggerLocalNotification(
        title: String,
        body: String,
        categoryIdentifier: String = "JUNTO_PAYMENT",
        delaySeconds: TimeInterval = 0.25
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(0.1, delaySeconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: "junto_notif_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    /// Agenda lembrete real de vencimento de cota do Pote Mensal ou Caixinha
    func scheduleMonthlyPotReminder(groupTitle: String, monthLabel: String, quotaFormatted: String, inSeconds: TimeInterval = 5.0) {
        triggerLocalNotification(
            title: "Lembrete do Pote • \(groupTitle)",
            body: "A parcela de \(monthLabel) (\(quotaFormatted)) está aberta. Pague via Pix para manter o grupo em 100%.",
            categoryIdentifier: "JUNTO_PAYMENT",
            delaySeconds: inSeconds
        )
    }

    // Exibe o banner nativo do iOS com som mesmo quando o aplicativo está aberto em primeiro plano
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
