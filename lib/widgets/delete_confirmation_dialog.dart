import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showDeleteConfirmationDialog({
  required String title,
  required String content,
  required VoidCallback onConfirm,
}) {
  Get.defaultDialog(
    title: title,
    middleText: content,
    textConfirm: "Delete",
    textCancel: "Cancel",
    confirmTextColor: Colors.white,
    buttonColor: Colors.redAccent,
    onConfirm: () {
      onConfirm();
      Get.back(); // Close the dialog
    },
    onCancel: () {
      Get.back(); // Close the dialog
    },
  );
}