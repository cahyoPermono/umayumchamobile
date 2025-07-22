import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:android_path_provider/android_path_provider.dart'; // New import
import 'package:get/get.dart'; // Import Get for Get.snackbar

/// Meminta izin penyimpanan dan mengembalikan jalur direktori yang sesuai.
/// Mengarahkan pengguna ke pengaturan aplikasi jika izin ditolak secara permanen.
Future<String?> getStorageDirectoryPath() async {
  if (kIsWeb) {
    // Di web, tidak ada konsep izin penyimpanan file sistem.
    // Unduhan biasanya ditangani oleh browser.
    debugPrint('Penyimpanan file tidak berlaku untuk web.');
    Get.snackbar('Info', 'Penyimpanan file tidak didukung di web.');
    return null;
  }

  // Periksa status izin saat ini
  var status = await Permission.manageExternalStorage.status;
  debugPrint('Current manageExternalStorage permission status: $status');

  // Jika izin belum diberikan, minta izin
  if (status.isDenied || status.isRestricted || status.isLimited) {
    debugPrint('Requesting manageExternalStorage permission...');
    status = await Permission.manageExternalStorage.request();
    debugPrint('Storage permission after request: $status');
  }

  // Jika izin diberikan
  if (status.isGranted) {
    debugPrint('Storage permission granted.');
    if (Platform.isAndroid) {
      final directoryPath = await AndroidPathProvider.downloadsPath;
      debugPrint('Android public downloads directory: $directoryPath');
      return directoryPath;
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      debugPrint('iOS application documents directory: ${directory.path}');
      return directory.path;
    }
  } else if (status.isPermanentlyDenied) {
    // Jika izin ditolak secara permanen, arahkan pengguna ke pengaturan aplikasi
    debugPrint(
      'Izin penyimpanan ditolak secara permanen. Harap aktifkan secara manual di pengaturan.',
    );
    Get.snackbar(
      'Peringatan',
      'Izin penyimpanan ditolak secara permanen. Harap aktifkan di Pengaturan Aplikasi.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () {
          openAppSettings();
        },
        child: const Text('Buka Pengaturan'),
      ),
    );
  } else {
    // Kasus lain (misal: ditolak oleh pengguna)
    debugPrint('Izin penyimpanan ditolak.');
    Get.snackbar(
      'Peringatan',
      'Izin penyimpanan ditolak. Tidak dapat menyimpan file.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  return null; // Mengembalikan null jika izin tidak diberikan atau direktori tidak ditemukan
}

/// Fungsi untuk mengekspor data PDF dan Excel.
/// Menerima bytes dari file PDF dan Excel, serta nama file yang diinginkan.
Future<void> exportPdfAndExcel({
  required List<int> pdfBytes,
  required String pdfFileName,
  required List<int> excelBytes,
  required String excelFileName,
}) async {
  debugPrint('Attempting to export PDF and Excel...');
  final directoryPath = await getStorageDirectoryPath();

  if (directoryPath != null) {
    try {
      // Simpan file PDF
      if (pdfBytes.isNotEmpty && pdfFileName.isNotEmpty) {
        final pdfFile = File('$directoryPath/$pdfFileName');
        await pdfFile.writeAsBytes(pdfBytes);
        debugPrint('PDF berhasil disimpan di: ${pdfFile.path}');
        Get.snackbar(
          'Sukses',
          'PDF berhasil disimpan di: ${pdfFile.path.split('/').last}',
        );
      } else {
        debugPrint('PDF bytes or filename is empty, skipping PDF export.');
      }

      // Simpan file Excel
      if (excelBytes.isNotEmpty && excelFileName.isNotEmpty) {
        final excelFile = File('$directoryPath/$excelFileName');
        await excelFile.writeAsBytes(excelBytes);
        debugPrint('Excel berhasil disimpan di: ${excelFile.path}');
        Get.snackbar(
          'Sukses',
          'Excel berhasil disimpan di: ${excelFile.path.split('/').last}',
        );
      } else {
        debugPrint('Excel bytes or filename is empty, skipping Excel export.');
      }
    } catch (e) {
      debugPrint('Gagal menyimpan file: $e');
      Get.snackbar('Error', 'Gagal menyimpan file: $e');
    }
  } else {
    debugPrint(
      'Tidak dapat menyimpan file karena izin tidak diberikan atau direktori tidak ditemukan.',
    );
    // Snackbar sudah ditangani di getStorageDirectoryPath()
  }
}
