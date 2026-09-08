import '../../../core/api/api_client.dart';

class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  /// Returns the updated `{phone, photo_url}` pair.
  Future<Map<String, dynamic>> updatePhone(String? phone) async {
    final response = await _api.put('/student/profile', data: {'phone': phone});

    return Map<String, dynamic>.from(response['data'] as Map);
  }

  /// Returns the new `photo_url`.
  Future<String?> uploadPhoto({required List<int> bytes, required String filename}) async {
    final response = await _api.uploadFile(
      '/student/profile/photo',
      fieldName: 'photo',
      fileBytes: bytes,
      filename: filename,
    );

    final data = Map<String, dynamic>.from(response['data'] as Map);

    return data['photo_url'] as String?;
  }
}
