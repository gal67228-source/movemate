import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../domain/move_plan.dart';

const _moveKey = 'current_move';

class MoveRepository {
  MoveRepository(this._storage);

  final LocalStorage _storage;

  MovePlan? getCurrentMove() {
    final json = _storage.readObject(_moveKey);
    return json == null ? null : MovePlan.fromJson(json);
  }

  Future<void> saveMove(MovePlan move) => _storage.writeObject(_moveKey, move.toJson());
}

final moveRepositoryProvider = FutureProvider<MoveRepository>((ref) async {
  return MoveRepository(await ref.watch(localStorageProvider.future));
});

final currentMoveProvider = FutureProvider<MovePlan?>((ref) async {
  final repository = await ref.watch(moveRepositoryProvider.future);
  return repository.getCurrentMove();
});
