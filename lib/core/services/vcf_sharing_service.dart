import 'dart:io';
import 'package:flutter/services.dart';

/// Simple VCF parser for preview purposes.
/// Parses VCF file to get contact count and basic info.
class VcfSharingService {
  static const MethodChannel _channel = MethodChannel('com.attendance/shared_data');
  
  /// Get the shared VCF file path if available.
  static Future<String?> getSharedVcfPath() async {
    try {
      final String? path = await _channel.invokeMethod('getSharedVcfPath');
      return path;
    } on PlatformException catch (e) {
      print('Error getting shared VCF path: ${e.message}');
      return null;
    }
  }

  /// Parse VCF file and return basic info for preview.
  static Future<VcfParseResult> parseVcfFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return VcfParseResult(
          success: false,
          contactCount: 0,
          fileName: filePath.split('/').last,
          error: 'File not found: $filePath',
        );
      }

      final content = await file.readAsString();
      final lines = content.split('\n');
      
      int contactCount = 0;
      final List<String> names = [];
      final List<String> errors = [];
      
      // Simple VCF parsing - look for BEGIN:VCARD and FN (full name) or N (name)
      bool inVCard = false;
      String? currentName;
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        
        if (trimmedLine.toUpperCase() == 'BEGIN:VCARD') {
          inVCard = true;
          currentName = null;
        } else if (trimmedLine.toUpperCase() == 'END:VCARD') {
          if (inVCard) {
            contactCount++;
            if (currentName != null) {
              names.add(currentName);
            }
          }
          inVCard = false;
        } else if (inVCard) {
          // Look for FN (Full Name) or N (Name)
          if (trimmedLine.toUpperCase().startsWith('FN:') || 
              trimmedLine.toUpperCase().startsWith('FN;')) {
            // Extract name after FN: or FN;...:
            final colonIndex = trimmedLine.indexOf(':');
            if (colonIndex != -1 && colonIndex < trimmedLine.length - 1) {
              currentName = trimmedLine.substring(colonIndex + 1).trim();
            }
          } else if (trimmedLine.toUpperCase().startsWith('N:') || 
                     trimmedLine.toUpperCase().startsWith('N;')) {
            // If we don't have FN, use N
            if (currentName == null) {
              final colonIndex = trimmedLine.indexOf(':');
              if (colonIndex != -1 && colonIndex < trimmedLine.length - 1) {
                // N format is usually: Last;First;Middle;Prefix;Suffix
                final nameParts = trimmedLine.substring(colonIndex + 1).split(';');
                if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
                  currentName = nameParts[0].trim(); // Use last name
                  if (nameParts.length > 1 && nameParts[1].isNotEmpty) {
                    currentName = '${nameParts[1].trim()} $currentName'; // First Last
                  }
                }
              }
            }
          }
        }
      }

      return VcfParseResult(
        success: contactCount > 0,
        contactCount: contactCount,
        fileName: filePath.split('/').last,
        names: names.take(5).toList(), // First 5 names for preview
        error: errors.isNotEmpty ? errors.join('\n') : null,
      );
    } catch (e) {
      return VcfParseResult(
        success: false,
        contactCount: 0,
        fileName: filePath.split('/').last,
        error: 'Failed to parse VCF: ${e.toString()}',
      );
    }
  }

  /// Clean up temporary VCF file
  static Future<void> cleanupTempFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error cleaning up temp file: $e');
    }
  }
}

class VcfParseResult {
  final bool success;
  final int contactCount;
  final String fileName;
  final List<String> names;
  final String? error;

  VcfParseResult({
    required this.success,
    required this.contactCount,
    required this.fileName,
    this.names = const [],
    this.error,
  });
}
