import SwiftUI
import UIKit

/// Protects sensitive chat content from screenshots and screen recording.
/// Uses a secure UITextField layer so iOS blacks out captures, plus an explicit dark overlay on capture events.
struct SecureScreenShield<Content: View>: View {
    let isEnabled: Bool
    @ViewBuilder let content: () -> Content

    @State private var isScreenCaptured = UIScreen.main.isCaptured
    @State private var showScreenshotWarning = false

    var body: some View {
        ZStack {
            if isEnabled {
                SecureContainerView(content: content())
            } else {
                content()
            }

            if isEnabled && (isScreenCaptured || showScreenshotWarning) {
                ZStack {
                    Color.black
                        .ignoresSafeArea()

                    VStack(spacing: 14) {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Proteção de Tela Ativa")
                            .font(AppTheme.Typography.headline())
                            .foregroundStyle(.white)
                        Text("Capturas e gravações de tela são bloqueadas nesta conversa.")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(Color.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .transition(.opacity)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
            isScreenCaptured = UIScreen.main.isCaptured
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            guard isEnabled else { return }
            withAnimation(.easeInOut(duration: 0.15)) {
                showScreenshotWarning = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showScreenshotWarning = false
                }
            }
        }
    }
}

private struct SecureContainerView<Content: View>: UIViewRepresentable {
    let content: Content

    func makeUIView(context: Context) -> UIView {
        let secureField = UITextField()
        secureField.isSecureTextEntry = true
        secureField.isUserInteractionEnabled = true

        guard let secureContainer = secureField.subviews.first else {
            let fallback = UIHostingController(rootView: content)
            fallback.view.backgroundColor = .clear
            return fallback.view
        }

        secureContainer.subviews.forEach { $0.removeFromSuperview() }
        secureContainer.isUserInteractionEnabled = true

        let host = UIHostingController(rootView: content)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear

        secureContainer.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: secureContainer.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: secureContainer.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: secureContainer.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: secureContainer.trailingAnchor)
        ])

        return secureContainer
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
