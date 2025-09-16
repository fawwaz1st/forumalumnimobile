import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user.dart';
import '../data/auth_repository.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>(
  (ref) => AuthController(ref),
);

final isLoggedInProvider = Provider<bool>((ref) {
  final state = ref.watch(authControllerProvider);
  return state.valueOrNull != null;
});

class AuthController extends StateNotifier<AsyncValue<User?>> {
  AuthController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<void> restoreSession() async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(authRepositoryProvider);
      final user = await repo.restoreSession();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password, {bool remember = true}) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(authRepositoryProvider);
      final res = await repo.login(email: email, password: password, remember: remember);
      state = AsyncValue.data(res.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(authRepositoryProvider);
      final res = await repo.register(name: name, email: email, password: password);
      state = AsyncValue.data(res.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    final repo = _ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(null);
  }

  void updateProfile({String? name, String? avatar, String? bio}) {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(
      name: name ?? current.name,
      avatar: avatar ?? current.avatar,
      bio: bio ?? current.bio,
    );
    state = AsyncValue.data(updated);
  }
}
