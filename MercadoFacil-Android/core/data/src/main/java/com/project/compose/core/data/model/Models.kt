package com.project.compose.core.data.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.SerialName

@Serializable
data class User(
    val id: String,
    val name: String,
    val cpf: String? = null,
    val birthDate: String? = null,
    val email: String,
    val phone: String,
    val username: String? = null,
    val visibleName: String? = null,
    val avatarURL: String? = null,
    val location: String,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val memberSince: String? = null,
    val isProfessional: Boolean = false,
    val rating: Double? = null,
    val responseTime: String? = null
)

@Serializable
data class Seller(
    val id: String,
    val user: User,
    val isVerified: Boolean = false,
    val rating: Double = 0.0,
    val reviewCount: Int = 0,
    val salesCount: Int = 0,
    val averageResponseTime: String,
    val bio: String
)

@Serializable
enum class ProductCondition(val value: String) {
    @SerialName("Novo") NEW("Novo"),
    @SerialName("Semi-novo") LIKE_NEW("Semi-novo"),
    @SerialName("Usado") USED("Usado")
}

@Serializable
data class Product(
    val id: String,
    val title: String,
    val description: String,
    val price: Double,
    val condition: ProductCondition,
    val categoryId: String,
    val sellerId: String,
    val location: String,
    val images: List<String>,
    val createdAt: String,
    val views: Int = 0,
    val isActive: Boolean = true,
    val deliveryMethod: String,
    val acceptsNegotiation: Boolean = false
)

@Serializable
data class Category(
    val id: String,
    val name: String,
    val description: String,
    val iconName: String
)

@Serializable
data class Message(
    val id: String,
    val senderId: String,
    val receiverId: String,
    val text: String,
    val imageName: String? = null,
    val timestamp: String,
    val isRead: Boolean = false
)

@Serializable
data class Conversation(
    val id: String,
    val productId: String,
    val participantId: String,
    val lastMessage: Message,
    val unreadCount: Int = 0
)

@Serializable
enum class NotificationType {
    @SerialName("message") MESSAGE,
    @SerialName("sale") SALE,
    @SerialName("purchase") PURCHASE,
    @SerialName("favorite") FAVORITE,
    @SerialName("system") SYSTEM
}

@Serializable
data class AppNotification(
    val id: String,
    val user_id: String,
    val type: String,
    val title: String,
    val body: String,
    val created_at: String,
    val is_read: Boolean = false
)
