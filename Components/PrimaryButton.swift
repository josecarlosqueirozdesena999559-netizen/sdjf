import SwiftUI

struct PrimaryButton: View {
    var title: String
    var action: () -> Void
    var isEnabled: Bool = true
    var isDestructive: Bool = false
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                Group {
                    if isDestructive {
                        Theme.error
                    } else if !isEnabled {
                        Theme.border
                    } else {
                        Theme.primary
                    }
                }
            )
            .foregroundColor(isEnabled ? .white : Theme.textSecondary)
            .cornerRadius(12)
        }
        .disabled(!isEnabled || isLoading)
    }
}
