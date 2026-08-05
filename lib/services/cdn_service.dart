import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CdnService {
  static const _baseUrl = 'http://202.6.239.245';

  static Future<String?> uploadImage({
    required Uint8List bytes,
    required String filename,
    String folder = 'bukti_chat',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/cdn/upload');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));
    request.fields['folder'] = folder;

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 201) {
      final json = jsonDecode(body);
      return json['data']?['url'] as String?;
    }
    return null;
  }

  static String? cdnUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '$_baseUrl$path';
  }
}
