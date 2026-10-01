import SwiftUI

@main struct ApurabraApp: App {
    @State private var isActive = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if isActive {
                RootView()
                    .tint(AppTheme.purple)
                    .onChange(of: scenePhase) { _, phase in
                        switch phase {
                        case .active:
                            // Limpa badge quando o usuário abre o app
                            NotificationManager.shared.clearBadge()
                            NotificationManager.shared.cancelBackgroundReminder()
                        case .background:
                            // Agenda lembrete para quando o usuário sair do app
                            NotificationManager.shared.scheduleBackgroundReminder()
                        default:
                            break
                        }
                    }
            } else {
                VStack(spacing: 24) {
                    Image("ApurabraLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130, height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                    Text("Apurabra")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.purple)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.background)
                .onAppear {
                    // Pede permissão de notificações ao abrir o app
                    NotificationManager.shared.requestPermission()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            isActive = true
                        }
                    }
                }
            }
        }
    }
}