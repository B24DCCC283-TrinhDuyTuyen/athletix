import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/constants/api_constants.dart';
import '../models/athlete_analysis.dart';
import '../models/video_analysis.dart';

class PoseAnalysisService {
  final http.Client _client;

  PoseAnalysisService({http.Client? client}) : _client = client ?? http.Client();

  /// Gửi ảnh lên server FastAPI để phân tích dáng chạy & góc khớp
  Future<AnalysisResult> analyzeImage(XFile imageFile, {double conf = 0.35}) async {
    try {
      final uri = Uri.parse(ApiConstants.analyzeEndpoint);
      final request = http.MultipartRequest('POST', uri);

      request.fields['conf'] = conf.toString();

      final bytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name.isNotEmpty ? imageFile.name : 'runner.jpg',
      );
      request.files.add(multipartFile);

      final streamedResponse = await _client.send(request).timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return AnalysisResult.fromJson(data);
      } else {
        throw Exception(
          'Lỗi máy chủ (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Không thể kết nối đến máy chủ AI: $e');
    }
  }

  /// Gửi video lên server để phân tích nhịp bước (Cadence SPM) & chuỗi chuyển động
  Future<VideoAnalysisResult> analyzeVideo(
    XFile videoFile, {
    double conf = 0.35,
    int maxDuration = 30,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.analyzeVideoEndpoint);
      final request = http.MultipartRequest('POST', uri);

      request.fields['conf'] = conf.toString();
      request.fields['max_duration'] = maxDuration.toString();

      final bytes = await videoFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: videoFile.name.isNotEmpty ? videoFile.name : 'runner_video.mp4',
      );
      request.files.add(multipartFile);

      // Phân tích video có thể cần nhiều thời gian hơn ảnh
      final streamedResponse = await _client.send(request).timeout(
        const Duration(minutes: 3),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return VideoAnalysisResult.fromJson(data);
      } else {
        throw Exception(
          'Lỗi phân tích video (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Lỗi xử lý video từ máy chủ AI: $e');
    }
  }

  /// Kiểm tra trạng thái hoạt động của Backend
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse(ApiConstants.healthEndpoint);
      final response = await _client.get(uri).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
