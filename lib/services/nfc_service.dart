import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  static Future<bool> isNfcAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  static Future<String?> readNfcTag() async {
    if (!await isNfcAvailable()) {
      throw Exception('NFC is not available on this device');
    }

    String? uid;
    
    await NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        // Try to get identifier from different tag types
        Uint8List? identifier;
        final tagData = tag.data as Map<String, dynamic>;
        
        // Try ISO14443 Type A
        if (tagData.containsKey('nfca')) {
          final nfcA = tagData['nfca'] as Map<String, dynamic>?;
          if (nfcA != null && nfcA['identifier'] != null) {
            identifier = Uint8List.fromList(List<int>.from(nfcA['identifier']));
          }
        }
        
        // Try ISO14443 Type B
        if (identifier == null && tagData.containsKey('nfcb')) {
          final nfcB = tagData['nfcb'] as Map<String, dynamic>?;
          if (nfcB != null && nfcB['identifier'] != null) {
            identifier = Uint8List.fromList(List<int>.from(nfcB['identifier']));
          }
        }
        
        // Try FeliCa
        if (identifier == null && tagData.containsKey('nfcf')) {
          final nfcF = tagData['nfcf'] as Map<String, dynamic>?;
          if (nfcF != null && nfcF['identifier'] != null) {
            identifier = Uint8List.fromList(List<int>.from(nfcF['identifier']));
          }
        }
        
        // Try ISO15693
        if (identifier == null && tagData.containsKey('nfcv')) {
          final nfcV = tagData['nfcv'] as Map<String, dynamic>?;
          if (nfcV != null && nfcV['identifier'] != null) {
            identifier = Uint8List.fromList(List<int>.from(nfcV['identifier']));
          }
        }

        if (identifier != null) {
          uid = identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join('').toUpperCase();
        }

        await NfcManager.instance.stopSession();
      },
    );

    return uid;
  }

  static void stopSession() {
    NfcManager.instance.stopSession();
  }
}