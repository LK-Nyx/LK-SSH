import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/storage/i_known_hosts_storage.dart';
import '../../data/storage/json_known_hosts_storage.dart';

part 'known_hosts_provider.g.dart';

@riverpod
Future<IKnownHostsStorage> knownHostsStorage(Ref ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return JsonKnownHostsStorage(dir);
}
