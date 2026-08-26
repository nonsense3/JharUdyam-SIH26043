import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:jharudyam_citizen/constants/app_constants.dart';
import 'package:jharudyam_citizen/models/problem_model.dart';
import 'package:jharudyam_citizen/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProblemRepository {
  Future<List<ProblemModel>> getProblems({String? category}) async {
    try {
      var query = SupabaseService.client
          .from('problems')
          .select();

      if (category != null && category != 'All') {
        query = query.ilike('category', '%$category%');
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((e) => ProblemModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch problems: $e');
    }
  }

  Future<List<ProblemModel>> getMyReports(String deviceId) async {
    try {
      final response = await SupabaseService.client
          .from('problems')
          .select()
          .eq('reporter_id', deviceId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => ProblemModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch my reports: $e');
    }
  }

  Future<ProblemModel> getProblemById(String id) async {
    try {
      final response = await SupabaseService.client
          .from('problems')
          .select()
          .eq('id', id)
          .single();

      return ProblemModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch problem: $e');
    }
  }

  Future<({String publicUrl, String path})> uploadImage(Uint8List imageBytes) async {
    try {
      final String path = '$uploadPrefix/${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}.jpg';
      
      await SupabaseService.client.storage
          .from(storageBucket)
          .uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final String publicUrl = SupabaseService.client.storage
          .from(storageBucket)
          .getPublicUrl(path);

      return (publicUrl: publicUrl, path: path);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<ProblemModel> submitProblem(ProblemModel problem) async {
    try {
      final response = await SupabaseService.client
          .from('problems')
          .insert(problem.toInsertJson())
          .select()
          .single();

      return ProblemModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to submit problem: $e');
    }
  }
}
