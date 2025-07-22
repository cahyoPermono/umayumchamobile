import 'package:uuid/uuid.dart';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha_ims/models/profile_model.dart';

class UserController extends GetxController {
  final _supabase = Supabase.instance.client;
  var users = <Profile>[].obs;
  var isLoading = false.obs;
  var isCreatingUserByAdmin = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      final response = await _supabase
          .from('user_profiles_view')
          .select('id, role, branch_id, email');
      users.value =
          (response as List).map((item) => Profile.fromJson(item)).toList();
    } catch (e) {
      log('Error fetching users: $e');
      Get.snackbar('Error', 'Failed to fetch users: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String role,
    String? branchId,
  }) async {
    try {
      isLoading.value = true;
      isCreatingUserByAdmin.value = true; // Set flag before signup

      // 1. Sign up user in Supabase Auth
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {}, // Explicitly pass empty data to avoid unexpected metadata
      );

      if (res.user == null) {
        throw 'User creation failed in Supabase Auth.';
      }

      // 2. Update the profile in public.profiles table (which was created by the trigger)
      await _supabase
          .from('profiles')
          .update({
            'role': role,
            'branch_id':
                branchId != null ? UuidValue.fromString(branchId) : null,
          })
          .eq('id', res.user!.id); // Use the ID from the newly created user

      fetchUsers(); // Refresh the list
      Get.back(); // Close the form screen
      Get.snackbar('Success', 'User created successfully!');
    } on AuthException catch (e) {
      log('AuthException creating user: ${e.message}');
      Get.snackbar('Auth Error', e.message);
    } catch (e) {
      log('Error creating user: $e');
      Get.snackbar('Error', 'Failed to create user: ${e.toString()}');
    } finally {
      isLoading.value = false;
      isCreatingUserByAdmin.value = false; // Reset flag
    }
  }

  Future<void> updateUserRole({
    required String userId,
    required String newRole,
    String? newBranchId,
  }) async {
    try {
      isLoading.value = true;
      await _supabase
          .from('profiles')
          .update({'role': newRole, 'branch_id': newBranchId})
          .eq('id', userId);

      fetchUsers(); // Refresh the list
      Get.back(); // Close the form screen
      Get.snackbar('Success', 'User role updated successfully!');
    } catch (e) {
      log('Error updating user role: $e');
      Get.snackbar('Error', 'Failed to update user role: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      isLoading.value = true;
      await _supabase.rpc('delete_auth_user', params: {'user_id': userId});

      fetchUsers(); // Refresh the list
      Get.snackbar('Success', 'User deleted successfully!');
    } catch (e) {
      log('Error deleting user: $e');
      Get.snackbar('Error', 'Failed to delete user: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
