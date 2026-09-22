import SwiftUI

struct CustomBackButtonModifier: ViewModifier {
    @Environment(\.presentationMode) var presentationMode
    
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                        .foregroundColor(Theme.primary)
                    }
                }
            }
    }
}

extension View {
    func customBackButton() -> some View {
        self.modifier(CustomBackButtonModifier())
    }
}
