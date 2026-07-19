import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../data/packing_repository.dart';
import '../domain/box_qr.dart';

class BoxScannerScreen extends ConsumerStatefulWidget {
  const BoxScannerScreen({super.key});

  @override
  ConsumerState<BoxScannerScreen> createState() => _BoxScannerScreenState();
}

class _BoxScannerScreenState extends ConsumerState<BoxScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_handled || capture.barcodes.isEmpty) {
      return;
    }
    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null) {
      return;
    }
    final boxId = boxIdFromQr(rawValue);
    if (boxId == null) {
      return;
    }
    final boxes = await ref.read(movingBoxesProvider.future);
    final exists = boxes.any((box) => box.id == boxId);
    if (!mounted) {
      return;
    }
    if (!exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הארגז לא נמצא במעבר הנוכחי')),
      );
      return;
    }
    _handled = true;
    await _controller.stop();
    if (mounted) {
      context.replace('/boxes/edit?id=$boxId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('סריקת QR של ארגז'),
        actions: [
          IconButton(
            tooltip: 'פנס',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleCapture,
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 4,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'מקם את קוד ה־QR של הארגז בתוך המסגרת',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
