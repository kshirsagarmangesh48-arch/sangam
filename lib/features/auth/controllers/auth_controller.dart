import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:sangam/core/utils/app_snackbar.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Rx<User?> firebaseUser = Rx<User?>(null);

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
  }

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      AppSnackBar.error('Error', e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
