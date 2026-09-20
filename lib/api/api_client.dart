import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  // Бодит утас дээр ажиллуулахад "localhost" нь утасны өөрийнх нь localhost-ыг
  // заадаг тул компьютерийн LAN IP хаягийг ашиглана. Сүлжээ солигдвол энэ IP-г
  // шинэчлэх, эсвэл --dart-define=API_BASE_URL=http://<IP>:8080 ашиглаарай.
  defaultValue: 'http://192.168.1.240:8080',
);

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class AuthResult {
  final String userId;
  final String userType;
  final String fullName;
  final String token;
  final String organizationId;
  final String? photoUrl;
  final String address;
  final String industry;

  AuthResult({
    required this.userId,
    required this.userType,
    required this.fullName,
    required this.token,
    required this.organizationId,
    this.photoUrl,
    required this.address,
    required this.industry,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    userId: json['userId'] as String,
    userType: json['userType'] as String,
    fullName: json['fullName'] as String,
    token: json['token'] as String,
    organizationId: json['organizationId'] as String,
    photoUrl: json['photoUrl'] as String?,
    address: json['address'] as String,
    industry: json['industry'] as String,
  );
}

class WorkspaceInfo {
  final String organizationId;
  final String businessName;
  final String? address;

  WorkspaceInfo({
    required this.organizationId,
    required this.businessName,
    this.address,
  });

  factory WorkspaceInfo.fromJson(Map<String, dynamic> json) => WorkspaceInfo(
    organizationId: json['organizationId'] as String,
    businessName: json['businessName'] as String,
    address: json['address'] as String?,
  );
}

class WorkspaceProfile {
  final String organizationId;
  final String businessName;
  final String? abn;
  final String? industry;
  final String? address;
  final String? phone;
  final int crewCount;
  final int adminCount;

  WorkspaceProfile({
    required this.organizationId,
    required this.businessName,
    this.abn,
    this.industry,
    this.address,
    this.phone,
    this.crewCount = 0,
    this.adminCount = 0,
  });

  factory WorkspaceProfile.fromJson(Map<String, dynamic> json) => WorkspaceProfile(
    organizationId: json['organizationId'] as String,
    businessName: json['businessName'] as String,
    abn: json['abn'] as String?,
    industry: json['industry'] as String?,
    address: json['address'] as String?,
    phone: json['phone'] as String?,
    crewCount: json['crewCount'] as int? ?? 0,
    adminCount: json['adminCount'] as int? ?? 0,
  );
}

class UserProfile {
  final String id;
  final String userType;
  final String fullName;
  final String username;
  final String? phone;
  final String? photoUrl;
  final DateTime? createdAt;
  final double? payRate;

  UserProfile({
    required this.id,
    required this.userType,
    required this.fullName,
    required this.username,
    this.phone,
    this.photoUrl,
    this.createdAt,
    this.payRate,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    userType: json['userType'] as String,
    fullName: json['fullName'] as String,
    username: json['username'] as String,
    phone: json['phone'] as String?,
    photoUrl: json['photoUrl'] as String?,
    createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
    payRate: (json['payRate'] as num?)?.toDouble(),
  );
}

class EmployeeDetail {
  final String id;
  final String fullName;
  final String? phone;
  final String? photoUrl;
  final double? payRate;

  EmployeeDetail({
    required this.id,
    required this.fullName,
    this.phone,
    this.photoUrl,
    this.payRate,
  });

  factory EmployeeDetail.fromJson(Map<String, dynamic> json) => EmployeeDetail(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    phone: json['phone'] as String?,
    photoUrl: json['photoUrl'] as String?,
    payRate: (json['payRate'] as num?)?.toDouble(),
  );
}

/// One day within a [TimesheetSummary]'s range — worked (hours logged), missing
/// (rostered on a job that day but no hours logged yet), or off (not rostered at all).
class TimesheetDay {
  final DateTime date;
  final String status;
  final double? hoursWorked;

  TimesheetDay({required this.date, required this.status, this.hoursWorked});

  factory TimesheetDay.fromJson(Map<String, dynamic> json) => TimesheetDay(
    date: DateTime.parse(json['date'] as String),
    status: json['status'] as String,
    hoursWorked: (json['hoursWorked'] as num?)?.toDouble(),
  );
}

class TimesheetSummary {
  final String employeeId;
  final String employeeFullName;
  final String? photoUrl;
  final double totalHours;
  final int loggedDays;
  final int missingLogs;
  final List<TimesheetDay> days;

  TimesheetSummary({
    required this.employeeId,
    required this.employeeFullName,
    this.photoUrl,
    required this.totalHours,
    required this.loggedDays,
    required this.missingLogs,
    this.days = const [],
  });

  factory TimesheetSummary.fromJson(Map<String, dynamic> json) => TimesheetSummary(
    employeeId: json['employeeId'] as String,
    employeeFullName: json['employeeFullName'] as String,
    photoUrl: json['photoUrl'] as String?,
    totalHours: (json['totalHours'] as num).toDouble(),
    loggedDays: json['loggedDays'] as int,
    missingLogs: json['missingLogs'] as int,
    days: (json['days'] as List<dynamic>? ?? const [])
        .map((e) => TimesheetDay.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class EmployeeHours {
  final String employeeId;
  final String fullName;
  final String? photoUrl;
  final double? hoursWorked;

  EmployeeHours({
    required this.employeeId,
    required this.fullName,
    this.photoUrl,
    this.hoursWorked,
  });

  factory EmployeeHours.fromJson(Map<String, dynamic> json) => EmployeeHours(
    employeeId: json['employeeId'] as String,
    fullName: json['fullName'] as String,
    photoUrl: json['photoUrl'] as String?,
    hoursWorked: (json['hoursWorked'] as num?)?.toDouble(),
  );
}

class AppNotification {
  final String id;
  final String message;
  final String? jobAdId;
  final DateTime createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.message,
    this.jobAdId,
    required this.createdAt,
    required this.read,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    message: json['message'] as String,
    jobAdId: json['jobAdId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    read: json['read'] as bool? ?? false,
  );
}

class WorkHourEntrySummary {
  final DateTime workDate;
  final double hoursWorked;
  final String? jobAddressLine;

  WorkHourEntrySummary({required this.workDate, required this.hoursWorked, this.jobAddressLine});

  factory WorkHourEntrySummary.fromJson(Map<String, dynamic> json) => WorkHourEntrySummary(
    workDate: DateTime.parse(json['workDate'] as String),
    hoursWorked: (json['hoursWorked'] as num).toDouble(),
    jobAddressLine: json['jobAddressLine'] as String?,
  );
}

class Employee {
  final String id;
  final String fullName;
  final String userType;
  final String? phone;
  final String? photoUrl;

  Employee({
    required this.id,
    required this.fullName,
    required this.userType,
    this.phone,
    this.photoUrl,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    userType: json['userType'] as String,
    phone: json['phone'] as String?,
    photoUrl: json['photoUrl'] as String?,
  );
}

class JobAdSummary {
  final String id;
  final String title;
  final String? jobType;
  final String? truck;
  final String? notes;
  final String status;
  final DateTime workDate;
  final String? startTime;
  final String? addressLine;
  final int requiredCount;
  final Employee? leader;
  final List<Employee> crew;
  final DateTime? createdAt;

  JobAdSummary({
    required this.id,
    required this.title,
    this.jobType,
    this.truck,
    this.notes,
    required this.status,
    required this.workDate,
    this.startTime,
    this.addressLine,
    required this.requiredCount,
    this.leader,
    this.crew = const [],
    this.createdAt,
  });

  factory JobAdSummary.fromJson(Map<String, dynamic> json) => JobAdSummary(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    jobType: json['jobType'] as String?,
    truck: json['truck'] as String?,
    notes: json['notes'] as String?,
    status: json['status'] as String? ?? 'OPEN',
    workDate: DateTime.parse(json['workDate'] as String),
    startTime: json['startTime'] as String?,
    addressLine: json['addressLine'] as String?,
    requiredCount: json['requiredCount'] as int? ?? 0,
    leader: json['leader'] == null
        ? null
        : Employee.fromJson(json['leader'] as Map<String, dynamic>),
    crew: (json['crew'] as List<dynamic>? ?? const [])
        .map((e) => Employee.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
  );
}

class ApiClient {
  static Map<String, dynamic> _decode(http.Response res) {
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Never _throwFromError(http.Response res, String fallback) {
    try {
      final data = _decode(res);
      throw ApiException((data['message'] ?? fallback).toString());
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(fallback);
    }
  }

  static Future<AuthResult> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode != 200) {
      _throwFromError(res, 'Нэвтрэх амжилтгүй боллоо');
    }
    return AuthResult.fromJson(_decode(res));
  }

  static Future<AuthResult> registerEmployee({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String organizationId,
    required String address,
    required String abn,
    XFile? photo,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBaseUrl/api/auth/register'),
    )
      ..fields['fullName'] = fullName
      ..fields['username'] = email
      ..fields['phone'] = phone
      ..fields['password'] = password
      ..fields['organizationId'] = organizationId
      ..fields['abn'] = abn
      ..fields['addressLine'] = address;

    if (photo != null) {
      request.files.add(
        http.MultipartFile.fromBytes('photo', await photo.readAsBytes(), filename: photo.name),
      );
    }

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);

    if (res.statusCode != 201) {
      _throwFromError(res, 'Бүртгэл амжилтгүй боллоо');
    }
    return AuthResult.fromJson(_decode(res));
  }

  static Future<AuthResult> createWorkspace({
    required String businessName,
    required String abn,
    required String industry,
    required String address,
    required String adminName,
    required String adminEmail,
    required String adminPhone,
    required String adminPassword,
    XFile? photo,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBaseUrl/api/workspaces'),
    )
      ..fields['businessName'] = businessName
      ..fields['abn'] = abn
      ..fields['industry'] = industry
      ..fields['address'] = address
      ..fields['adminName'] = adminName
      ..fields['adminEmail'] = adminEmail
      ..fields['phone'] = adminPhone
      ..fields['adminPassword'] = adminPassword;

    if (photo != null) {
      request.files.add(
        http.MultipartFile.fromBytes('photo', await photo.readAsBytes(), filename: photo.name),
      );
    }

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);

    if (res.statusCode != 201) {
      _throwFromError(res, 'Байгууллага үүсгэхэд алдаа гарлаа');
    }
    return AuthResult.fromJson(_decode(res));
  }

  /// Токеноор баталгаажсан хэрэглэгчийн харьяалагдах байгууллагын бүрэн
  /// мэдээллийг backend-ээс шинээр татна. Session дотор кэшлэгдсэн industry/
  /// address-аас илүү, ABN болон утасны дугаар зэрэг бүрэн мэдээллийг авчирна.
  static Future<WorkspaceProfile> getMyWorkspace(String token) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/api/workspaces/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      _throwFromError(res, 'Байгууллагын мэдээлэл татахад алдаа гарлаа');
    }
    return WorkspaceProfile.fromJson(_decode(res));
  }

  /// Токеноор баталгаажсан админы байгууллагад бүртгэлтэй Employee
  /// статустай бүх ажилчдын жагсаалтыг татна. Backend JSON массив
  /// буцаадаг тул Map-руу decode хийдэг _decode()-г ашиглахгүй.
  static Future<List<Employee>> getEmployeeList(String token) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/api/workspaces/getEmployees'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      _throwFromError(res, 'Ажилчдын жагсаалт татахад алдаа гарлаа');
    }
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return list.map((e) => Employee.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Шинэ ажлын зар үүсгэнэ. [draft] true бол "Save as draft" (DRAFT
  /// төлөвтэй), false бол шууд crew-д publish хийнэ (OPEN төлөвтэй).
  static Future<void> createJobAd({
    required String token,
    required DateTime workDate,
    required int startHour,
    required int startMinute,
    required String addressLine,
    required String jobType,
    String? leaderId,
    String? truck,
    List<String> crewIds = const [],
    String? notes,
    bool draft = false,
  }) async {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final res = await http.post(
      Uri.parse('$apiBaseUrl/api/job-ads/job-create-post'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'workDate':
            '${workDate.year}-${twoDigits(workDate.month)}-${twoDigits(workDate.day)}',
        'startTime': '${twoDigits(startHour)}:${twoDigits(startMinute)}:00',
        'addressLine': addressLine,
        'jobType': jobType,
        if (leaderId != null) 'leaderId': leaderId,
        if (truck != null) 'truck': truck,
        'crewIds': crewIds,
        if (notes != null) 'notes': notes,
        'draft': draft,
      }),
    );
    if (res.statusCode != 201) {
      _throwFromError(res, 'something is wrong.');
    }
  }

  /// Байгаа ажлын зарыг шинэчилнэ (талбарууд, ахлагч, баг). [jobAdId]-аар
  /// тодорхойлогдоно.
  static Future<void> updateJobAd({
    required String token,
    required String adminId,
    required String jobAdId,
    required DateTime workDate,
    required int startHour,
    required int startMinute,
    required String addressLine,
    required String jobType,
    String? leaderId,
    String? truck,
    List<String> crewIds = const [],
    String? notes,
    bool draft = false,
  }) async {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final res = await http.put(
      Uri.parse('$apiBaseUrl/api/admins/$adminId/job-ads/$jobAdId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'workDate':
            '${workDate.year}-${twoDigits(workDate.month)}-${twoDigits(workDate.day)}',
        'startTime': '${twoDigits(startHour)}:${twoDigits(startMinute)}:00',
        'addressLine': addressLine,
        'jobType': jobType,
        if (leaderId != null) 'leaderId': leaderId,
        if (truck != null) 'truck': truck,
        'crewIds': crewIds,
        if (notes != null) 'notes': notes,
        'draft': draft,
      }),
    );
    if (res.statusCode != 200) {
      _throwFromError(res, 'Ажлын зар шинэчлэхэд алдаа гарлаа');
    }
  }

  /// Тухайн ажлын зар дээрх багийн гишүүн бүрийн (ахлагчийг оролцуулаад)
  /// одоо хүртэл бүртгэгдсэн ажилласан цагийг татна.
  static Future<List<EmployeeHours>> getJobHours({
    required String token,
    required String adminId,
    required String jobAdId,
  }) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/api/admins/$adminId/job-ads/$jobAdId/hours'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      _throwFromError(res, 'Ажилласан цаг татахад алдаа гарлаа');
    }
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return list.map((e) => EmployeeHours.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Нэвтэрсэн админы байгууллагад үүсгэсэн, [from]..[to] хооронд төлөвлөгдсөн
  /// ажлын зарын жагсаалтыг татна (dashboard-д ашиглана).
  static Future<List<JobAdSummary>> getJobAds({
    required String token,
    required String adminId,
    required DateTime from,
    required DateTime to,
  }) async {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String iso(DateTime d) => '${d.year}-${twoDigits(d.month)}-${twoDigits(d.day)}';

    final uri = Uri.parse('$apiBaseUrl/api/admins/$adminId/job-ads').replace(
      queryParameters: {'from': iso(from), 'to': iso(to)},
    );
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) {
      _throwFromError(res, 'Ажлын жагсаалт татахад алдаа гарлаа');
    }
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return list.map((e) => JobAdSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Нэвтэрсэн хэрэглэгчийн (Admin эсвэл Employee аль ч байсан) өөрийнх нь
  /// профайлыг татна ("User profile" дэлгэц үүнийг ашиглана).
  static Future<UserProfile> getMyProfile(String token) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/api/users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      _throwFromError(res, 'Профайл татахад алдаа гарлаа');
    }
    return UserProfile.fromJson(_decode(res));
  }

  /// Админы байгууллагад бүртгэлтэй ажилчдын жагсаалтыг цалингийн хувь
  /// хэмжээний хамт татна (Pay rates дэлгэц).
  static Future<List<EmployeeDetail>> getEmployeesWithRates({
    required String token,
    required String adminId,
  }) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/api/admins/$adminId/employees'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      _throwFromError(res, 'Ажилчдын жагсаалт татахад алдаа гарлаа');
    }
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return list.map((e) => EmployeeDetail.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> updatePayRate({
    required String token,
    required String adminId,
    required String employeeId,
    required double payRate,
  }) async {
    final res = await http.put(
      Uri.parse('$apiBaseUrl/api/admins/$adminId/employees/$employeeId/pay-rate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'payRate': payRate}),
    );
    if (res.statusCode != 204) {
      _throwFromError(res, 'Цалингийн хувь хэмжээ хадгалахад алдаа гарлаа');
    }
  }

  /// [from]..[to] хооронд ажилтан тус бүрийн ажилласан цаг болон дутуу
  /// бүртгэлийн тоог татна (Timesheets дэлгэц).
  static Future<List<TimesheetSummary>> getTimesheets({
    required String token,
    required String adminId,
    required DateTime from,
    required DateTime to,
  }) async {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String iso(DateTime d) => '${d.year}-${twoDigits(d.month)}-${twoDigits(d.day)}';

    final uri = Uri.parse('$apiBaseUrl/api/admins/$adminId/timesheets').replace(
      queryParameters: {'from': iso(from), 'to': iso(to)},
    );
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) {
      _throwFromError(res, 'Ажилласан цагийн тайлан татахад алдаа гарлаа');
    }
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return list.map((e) => TimesheetSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Тухайн ажилтны сүүлийн ажилласан цагийн бүртгэлүүд (Payroll calculator-ийн
  /// "Recent entries" хэсэгт ашиглана).
  static Future<List<WorkHourEntrySummary>> getRecentWorkHours({
    required String token,
    required String adminId,
    required String employeeId,
  }) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/api/admins/$adminId/employees/$employeeId/work-hours/recent'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      _throwFromError(res, 'Ажилласан цагийн түүх татахад алдаа гарлаа');
    }
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return list.map((e) => WorkHourEntrySummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Тухайн ажлын зар дээр ажилтны ажилласан цагийг хадгална. Хэрэв ажилтан
  /// зөвхөн job-create үед crew-д нэмэгдсэн (Assignment үүсээгүй) бол backend
  /// автоматаар Assignment үүсгээд дараа нь цагийг бүртгэнэ.
  static Future<void> recordHoursForJob({
    required String token,
    required String adminId,
    required String jobAdId,
    required String employeeId,
    required DateTime workDate,
    required double hours,
  }) async {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final res = await http.post(
      Uri.parse('$apiBaseUrl/api/admins/$adminId/job-ads/$jobAdId/work-hours'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'employeeId': employeeId,
        'workDate':
            '${workDate.year}-${twoDigits(workDate.month)}-${twoDigits(workDate.day)}',
        'hoursWorked': hours,
      }),
    );
    if (res.statusCode != 201) {
      _throwFromError(res, 'Ажилласан цаг хадгалахад алдаа гарлаа');
    }
  }

  /// Нэвтэрсэн ажилтны харьяалагдах, [from]..[to] хооронд төлөвлөгдсөн ажлын
  /// зарууд, баг гишүүдийн нэрийн хамт (Home · job posts feed-д ашиглана).
  static Future<List<JobAdSummary>> getMyJobPosts({
    required String token,
    required String employeeId,
    required DateTime from,
    required DateTime to,
  }) async {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String iso(DateTime d) => '${d.year}-${twoDigits(d.month)}-${twoDigits(d.day)}';

    final uri = Uri.parse('$apiBaseUrl/api/employees/$employeeId/job-ads/summary').replace(
      queryParameters: {'from': iso(from), 'to': iso(to)},
    );
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) {
      _throwFromError(res, 'Ажлын зарын жагсаалт татахад алдаа гарлаа');
    }
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return list.map((e) => JobAdSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Нэвтэрсэн ажилтны өөрийнх нь ажилласан цагийн бүртгэлүүд [from]..[to]
  /// хооронд (My timesheet дэлгэц).
  static Future<List<WorkHourEntrySummary>> getMyWorkHours({
    required String token,
    required String employeeId,
    required DateTime from,
    required DateTime to,
  }) async {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String iso(DateTime d) => '${d.year}-${twoDigits(d.month)}-${twoDigits(d.day)}';

    final uri = Uri.parse('$apiBaseUrl/api/employees/$employeeId/work-hours').replace(
      queryParameters: {'from': iso(from), 'to': iso(to)},
    );
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) {
      _throwFromError(res, 'Ажилласан цагийн түүх татахад алдаа гарлаа');
    }
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return list.map((e) => WorkHourEntrySummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Ажилтны мэдэгдлийн жагсаалт (шинэ/шинэчлэгдсэн ажлын зар гэх мэт).
  static Future<List<AppNotification>> getMyNotifications({
    required String token,
    required String employeeId,
  }) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/api/employees/$employeeId/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      _throwFromError(res, 'Мэдэгдэл татахад алдаа гарлаа');
    }
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> markNotificationRead({
    required String token,
    required String employeeId,
    required String notificationId,
  }) async {
    final res = await http.put(
      Uri.parse('$apiBaseUrl/api/employees/$employeeId/notifications/$notificationId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 204) {
      _throwFromError(res, 'Мэдэгдэл шинэчлэхэд алдаа гарлаа');
    }
  }

  static Future<void> markAllNotificationsRead({
    required String token,
    required String employeeId,
  }) async {
    final res = await http.put(
      Uri.parse('$apiBaseUrl/api/employees/$employeeId/notifications/read-all'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 204) {
      _throwFromError(res, 'Мэдэгдэл шинэчлэхэд алдаа гарлаа');
    }
  }

  static Future<WorkspaceInfo?> lookupWorkspace(String organizationId) async {
    if (organizationId.trim().isEmpty) return null;
    final res = await http.get(
      Uri.parse('$apiBaseUrl/api/workspaces/${Uri.encodeComponent(organizationId.trim())}'),
    );
    if (res.statusCode != 200) return null;
    return WorkspaceInfo.fromJson(_decode(res));
  }
}
