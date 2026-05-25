// lib/src/models/support_ticket_models.dart

class SupportTicketResponse {
  final bool? success;
  final List<SupportTicket>? data;
  final Pagination? pagination;

  SupportTicketResponse({
    this.success,
    this.data,
    this.pagination,
  });

  factory SupportTicketResponse.fromJson(Map<String, dynamic> json) {
    return SupportTicketResponse(
      success: json['success'] as bool?,
      data: json['data'] != null
          ? List<SupportTicket>.from(
              (json['data'] as List).map(
                (x) => SupportTicket.fromJson(x as Map<String, dynamic>),
              ),
            )
          : [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Pagination {
  final int? totalItems;
  final int? totalPages;
  final int? currentPage;
  final int? perPage;

  Pagination({
    this.totalItems,
    this.totalPages,
    this.currentPage,
    this.perPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      totalItems: json['totalItems'] as int?,
      totalPages: json['totalPages'] as int?,
      currentPage: json['currentPage'] as int?,
      perPage: json['perPage'] as int?,
    );
  }
}

class SupportTicket {
  final int? ticketId;
  final String? reportTitle;
  final String? reportText;
  final String? reportMedia1;
  final String? reportMedia2;
  final String? reportMedia3;
  final String? reportMedia4;
  final String? reportMedia5;
  final String? reportStatus;
  final String? adminRemarks;
  final String? superAdminRemarks;
  final String? createdAt;
  final String? updatedAt;
  final int? adminId;
  final int? userId;
  final Admin? admin;
  final User? user;
  final List<SupportTicketChat>? supportTicketChats;

  SupportTicket({
    this.ticketId,
    this.reportTitle,
    this.reportText,
    this.reportMedia1,
    this.reportMedia2,
    this.reportMedia3,
    this.reportMedia4,
    this.reportMedia5,
    this.reportStatus,
    this.adminRemarks,
    this.superAdminRemarks,
    this.createdAt,
    this.updatedAt,
    this.adminId,
    this.userId,
    this.admin,
    this.user,
    this.supportTicketChats,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      ticketId: json['ticket_id'] as int?,
      reportTitle: json['report_title'] as String?,
      reportText: json['report_text'] as String?,
      reportMedia1: json['report_media_1'] as String?,
      reportMedia2: json['report_media_2'] as String?,
      reportMedia3: json['report_media_3'] as String?,
      reportMedia4: json['report_media_4'] as String?,
      reportMedia5: json['report_media_5'] as String?,
      reportStatus: json['report_status'] as String?,
      adminRemarks: json['admin_remarks'] as String?,
      superAdminRemarks: json['super_admin_remarks'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      adminId: json['admin_id'] as int?,
      userId: json['user_id'] as int?,
      admin: json['Admin'] != null
          ? Admin.fromJson(json['Admin'] as Map<String, dynamic>)
          : null,
      user: json['User'] != null
          ? User.fromJson(json['User'] as Map<String, dynamic>)
          : null,
      supportTicketChats: json['Support_ticket_chats'] != null
          ? List<SupportTicketChat>.from(
              (json['Support_ticket_chats'] as List).map(
                (x) => SupportTicketChat.fromJson(x as Map<String, dynamic>),
              ),
            )
          : [],
    );
  }

  // Get the last message from the support ticket chats
  String? getLastMessage() {
    if (supportTicketChats != null && supportTicketChats!.isNotEmpty) {
      return supportTicketChats!.first.messageContent;
    }
    return reportText; // Return the report text if no chat messages
  }

  // Check if the ticket is open based on status
  bool isOpen() {
    return reportStatus?.toLowerCase() == 'pending';
  }
}

class Admin {
  final int? adminId;
  final String? adminName;

  Admin({
    this.adminId,
    this.adminName,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      adminId: json['admin_id'] as int?,
      adminName: json['admin_name'] as String?,
    );
  }
}

class User {
  final String? profileImage;
  final int? userId;
  final String? userName;
  final String? firstName;
  final String? lastName;
  final int? lastSeen;
  final bool? blockedByAdmin;
  final bool? isAccountDeleted;

  User({
    this.profileImage,
    this.userId,
    this.userName,
    this.firstName,
    this.lastName,
    this.lastSeen,
    this.blockedByAdmin,
    this.isAccountDeleted,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      profileImage: json['profile_image'] as String?,
      userId: json['user_id'] as int?,
      userName: json['user_name'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      lastSeen: json['last_seen'] as int?,
      blockedByAdmin: json['Blocked_by_admin'] as bool?,
      isAccountDeleted: json['is_account_deleted'] as bool?,
    );
  }
}

class SupportTicketChat {
  final int? chatId;
  final String? messageType;
  final String? messageContent;
  final bool? userSeen;
  final bool? adminSeen;
  final int? senderId;
  final String? createdAt;
  final String? updatedAt;
  final int? adminId;
  final int? ticketId;
  final int? userId;

  SupportTicketChat({
    this.chatId,
    this.messageType,
    this.messageContent,
    this.userSeen,
    this.adminSeen,
    this.senderId,
    this.createdAt,
    this.updatedAt,
    this.adminId,
    this.ticketId,
    this.userId,
  });

  factory SupportTicketChat.fromJson(Map<String, dynamic> json) {
    return SupportTicketChat(
      chatId: json['chat_id'] as int?,
      messageType: json['message_type'] as String?,
      messageContent: json['message_content'] as String?,
      userSeen: json['user_seen'] as bool?,
      adminSeen: json['admin_seen'] as bool?,
      senderId: json['sender_id'] as int?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      adminId: json['admin_id'] as int?,
      ticketId: json['ticket_id'] as int?,
      userId: json['user_id'] as int?,
    );
  }
}
