import SwiftUI

struct PrimaryButton: View {
    var title: String
    var isEnabled: Bool = true
    var isDestructive: Bool = false
    var isLoading: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
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
