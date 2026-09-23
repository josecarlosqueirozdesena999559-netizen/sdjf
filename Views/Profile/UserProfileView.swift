import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            if let user = authViewModel.currentUser {
                SellerProfileView(
                    seller: Seller(
                        id: user.id,
                        user: user,
                        isVerified: false,
                        rating: user.rating ?? 0,
                        reviewCount: 0,
                        salesCount: 0,
                        averageResponseTime: user.responseTime ?? "-",
                        bio: user.bio ?? ""
                    ),
                    showsBackButton: false
                )
            } else {
                ProgressView()
            }
        }
    }
}