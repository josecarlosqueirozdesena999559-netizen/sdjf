import UserNotifications
import UIKit

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    // IDs das notificações
    private let electionStartedID = "apurabra.election.started"
    private let newVotesID        = "apurabra.election.newvotes"
    private let backgroundCheckID = "apurabra.background.check"

    // Último total de votos que conhecemos (para detectar novos votos)
    private var lastKnownVotes: Int = UserDefaults.standard.integer(forKey: "lastKnownVotes")

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Pedir Permissão
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    // MARK: - Notificação: Apuração Começou
    func scheduleElectionStarted() {
        center.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .authorized else { return }
            self?.sendNow(
                id: self?.electionStartedID ?? "",
                title: "🗳️ A apuração começou!",
                body: "Os primeiros votos já foram registrados. Acompanhe ao vivo no Apurabra.",
                badge: 1
            )
        }
    }

    // MARK: - Notificação: Novos Votos (chamada ao entrar em background)
    func checkAndNotifyNewVotes(currentVotes: Int) {
        guard currentVotes > lastKnownVotes, lastKnownVotes > 0 else {
            // Apenas atualiza o valor, sem notificar ainda
            if currentVotes > 0 {
                lastKnownVotes = currentVotes
                UserDefaults.standard.set(currentVotes, forKey: "lastKnownVotes")
            }
            return
        }
        lastKnownVotes = currentVotes
        UserDefaults.standard.set(currentVotes, forKey: "lastKnownVotes")

        center.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .authorized else { return }
            self?.sendNow(
                id: self?.newVotesID ?? "",
                title: "📊 Novos votos inseridos!",
                body: "A contagem avançou. Acompanhe a apuração em tempo real no Apurabra.",
                badge: 1
            )
        }
    }

    // MARK: - Notificação local agendada (para verificar em background)
    func scheduleBackgroundReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [backgroundCheckID])

        let content = UNMutableNotificationContent()
        content.title = "📊 Acompanhe a apuração"
        content.body  = "Novos votos podem ter sido registrados. Toque para ver os resultados."
        content.sound = .default
        content.badge = 1

        // Dispara após 30 minutos em background
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: backgroundCheckID, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelBackgroundReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [backgroundCheckID])
    }

    // MARK: - Limpar badge ao abrir
    func clearBadge() {
        center.setBadgeCount(0)
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Helper interno
    private func sendNow(id: String, title: String, body: String, badge: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        content.badge = NSNumber(value: badge)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Delegate: exibe notificação mesmo com app aberto
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
