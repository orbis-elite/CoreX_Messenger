class ChatMessage {
  final int chatId;
  final String messageType;
  final String messageContent;
  final bool userSeen;
  final bool adminSeen;
  final int senderId; // 0 = user, 1 = admin
  final DateTime createdAt;
  final DateTime updatedAt;
  final int adminId;
  final int ticketId;
  final int userId;
  final Admin admin;
  final User user;
  final SupportTicketInfo supportTicket;

  ChatMessage({
    required this.chatId,
    required this.messageType,
    required this.messageContent,
    required this.userSeen,
    required this.adminSeen,
    required this.senderId,
    required this.createdAt,
    required this.updatedAt,
    required this.adminId,
    required this.ticketId,
    required this.userId,
    required this.admin,
    required this.user,
    required this.supportTicket,
  });
}

class Admin {
  final String profilePic;
  final int adminId;
  final String adminName;

  Admin({
    required this.profilePic,
    required this.adminId,
    required this.adminName,
  });
}

class User {
  final String profileImage;
  final int userId;
  final String userName;
  final String firstName;
  final String lastName;
  final int lastSeen;
  final bool blockedByAdmin;
  final bool isAccountDeleted;

  User({
    required this.profileImage,
    required this.userId,
    required this.userName,
    required this.firstName,
    required this.lastName,
    required this.lastSeen,
    required this.blockedByAdmin,
    required this.isAccountDeleted,
  });
}

class SupportTicketInfo {
  final int ticketId;
  final String reportTitle;
  final String reportText;
  final String reportStatus;
  final String adminRemarks;
  final String superAdminRemarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int adminId;
  final int userId;
  final List<String> mediaFiles;

  SupportTicketInfo({
    required this.ticketId,
    required this.reportTitle,
    required this.reportText,
    required this.reportStatus,
    required this.adminRemarks,
    required this.superAdminRemarks,
    required this.createdAt,
    required this.updatedAt,
    required this.adminId,
    required this.userId,
    required this.mediaFiles,
  });
}
