import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/storage/i_storage_service.dart';
import '../../data/storage/json_storage_service.dart';

part 'storage_provider.g.dart';

@riverpod
Future<IStorageService> storage(Ref ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final dataDir = Directory('${dir.path}/lk_ssh_data');
  if (!await dataDir.exists()) await dataDir.create(recursive: true);
  return JsonStorageService(dataDir);
}
