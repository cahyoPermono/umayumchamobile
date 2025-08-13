import 'package:flutter/material.dart'; // For debugPrint
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha_ims/controllers/branch_controller.dart';

class AuthController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var currentUser = Rx<User?>(null);
  var userRole = ''.obs; // To store the user's role
  var userBranchId = Rx<String?>(
    null,
  ); // New: To store the user's assigned branch ID

  @override
  void onInit() {
    super.onInit();
    isLoading.value = true; // Start in a loading state

    // The onAuthStateChange stream fires immediately with the current auth state.
    // This single listener will handle both initial load and subsequent changes.
    supabase.auth.onAuthStateChange.listen((data) async {
      debugPrint('Auth state changed: ${data.event}');
      final Session? session = data.session;
      currentUser.value = session?.user;

      if (session != null) {
        debugPrint('User session found. Fetching profile...');
        await _fetchUserProfile(session.user.id);
      } else {
        debugPrint('No user session found. Clearing profile.');
        userRole.value = ''; // Clear role on sign out
        userBranchId.value = null; // Clear branch ID on sign out
      }
      isLoading.value = false; // End loading state after processing
    });
  }

  Future<void> _fetchUserProfile(String userId) async {
    try {
      final response =
          await supabase
              .from('profiles')
              .select('role, branch_id') // Select both role and branch_id
              .eq('id', userId)
              .single();

      userRole.value = response['role'] ?? 'user';
      userBranchId.value = response['branch_id'] as String?;
      debugPrint(
        'User profile fetched: Role=${userRole.value}, BranchID=${userBranchId.value}',
      );
      // Explicitly fetch branches after user profile is loaded
      Get.find<BranchController>().fetchBranches();
    } catch (e) {
      debugPrint('Error fetching user profile: ${e.toString()}');
      userRole.value = 'user'; // Default to 'user' on error
      userBranchId.value = null; // Default to null on error
      Get.snackbar('Profile Error', 'Could not fetch user profile.');
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
        debugPrint('Sign up successful: ${response.user?.email}');
        Get.snackbar(
          'Success',
          'Sign up successful! Please check your email for verification.',
        );
      } else if (response.session == null) {
        debugPrint('Sign up failed: No user or session');
        Get.snackbar('Error', 'Sign up failed. Please try again.');
      }
    } on AuthException catch (e) {
      debugPrint('AuthException during sign up: ${e.message}');
      Get.snackbar('Auth Error', e.message);
    } catch (e) {
      debugPrint('Unexpected error during sign up: ${e.toString()}');
      Get.snackbar('Error', 'An unexpected error occurred.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      isLoading.value = true;
      await supabase.auth.signInWithPassword(email: email, password: password);
      debugPrint('Sign in successful for: $email');
      // The onAuthStateChange listener will handle redirection and role fetching.
    } on AuthException catch (e) {
      debugPrint('AuthException during sign in: ${e.message}');
      Get.snackbar('Auth Error', e.message);
      isLoading.value = false; // Set isLoading to false on error
    } catch (e) {
      debugPrint('Unexpected error during sign in: ${e.toString()}');
      Get.snackbar('Error', 'An unexpected error occurred.');
      isLoading.value = false; // Set isLoading to false on error
    }
  }

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await supabase.auth.signOut();
      debugPrint('Sign out successful');
      // The onAuthStateChange listener will handle redirection.
    } on AuthException catch (e) {
      debugPrint('AuthException during sign out: ${e.message}');
      Get.snackbar('Auth Error', e.message);
    } catch (e) {
      debugPrint('Unexpected error during sign out: ${e.toString()}');
      Get.snackbar('Error', 'An unexpected error occurred.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      isLoading.value = true;
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      Get.snackbar(
        'Success',
        'Password updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on AuthException catch (e) {
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      isLoading.value = true;
      await supabase.auth.resetPasswordForEmail(email);
      Get.snackbar(
        'Success',
        'Password reset link sent to your email.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on AuthException catch (e) {
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
