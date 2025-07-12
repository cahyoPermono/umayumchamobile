import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha/screens/sign_in_screen.dart';
import 'package:umayumcha/screens/dashboard_screen.dart';

class AuthController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var currentUser = Rx<User?>(null);
  var userRole = ''.obs; // To store the user's role

  @override
  void onInit() {
    // Get initial user session and role
    final initialUser = supabase.auth.currentUser;
    if (initialUser != null) {
      currentUser.value = initialUser;
      _fetchUserRole(initialUser.id);
    }

    // Listen to auth state changes
    supabase.auth.onAuthStateChange.listen((data) async {
      final Session? session = data.session;
      currentUser.value = session?.user;

      if (session != null) {
        await _fetchUserRole(session.user.id);
        Get.offAll(() => DashboardScreen());
      } else {
        userRole.value = ''; // Clear role on sign out
        Get.offAll(() => const SignInScreen());
      }
    });
    super.onInit();
  }

  Future<void> _fetchUserRole(String userId) async {
    try {
      final response =
          await supabase
              .from('profiles')
              .select('role')
              .eq('id', userId)
              .single();

      userRole.value = response['role'] ?? 'user';
    } catch (e) {
      // Handle cases where the profile might not exist yet or other errors
      userRole.value = 'user'; // Default to 'user' on error
      Get.snackbar('Role Error', 'Could not fetch user role.');
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    try {
      isLoading.value = true;
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      // The onAuthStateChange listener will handle redirection.
      if (response.user != null) {
        Get.snackbar(
          'Success',
          'Sign up successful! Please check your email for verification.',
        );
      } else if (response.session == null) {
        Get.snackbar('Error', 'Sign up failed. Please try again.');
      }
    } on AuthException catch (e) {
      Get.snackbar('Auth Error', e.message);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      isLoading.value = true;
      await supabase.auth.signInWithPassword(email: email, password: password);
      // The onAuthStateChange listener will handle redirection and role fetching.
    } on AuthException catch (e) {
      Get.snackbar('Auth Error', e.message);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await supabase.auth.signOut();
      // The onAuthStateChange listener will handle redirection.
    } on AuthException catch (e) {
      Get.snackbar('Auth Error', e.message);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred.');
    } finally {
      isLoading.value = false;
    }
  }
}
