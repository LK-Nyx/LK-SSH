import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/storage/i_password_storage.dart';
import '../../data/storage/secure_password_storage.dart';

part 'password_storage_provider.g.dart';

@riverpod
IPasswordStorage passwordStorage(Ref ref) => SecurePasswordStorage();
