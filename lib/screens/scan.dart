import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as contacts;

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool hasPermission = false;
  bool isFlashOn = false;
  late MobileScannerController scannerController;

  @override
  void initState() {
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
    
    );
    _checkPermission();
    super.initState();
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      hasPermission = status.isGranted;
    });
  }

  Future<void> _processScannedData(String? data) async {
    if (data == null) return;
    scannerController.stop();

    String type = 'text';
    if (data.startsWith('BEGIN:VCARD')) {
      type = 'contact';
    } else if (data.startsWith('http://') || data.startsWith('https://')) {
      type = 'url';
    }
    showModalBottomSheet(
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, controller) => Container(
                decoration: BoxDecoration(
                  color: Colors.cyan,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      "Scanned Result:",
                      softWrap: true,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Text(
                      'Type:${type.toUpperCase()}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Expanded(
                        child: SingleChildScrollView(
                      controller: controller,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            data,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          SizedBox(
                            height: 24,
                          ),
                          type == 'url'
                              ? ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: Icon(Icons.open_in_new),
                                  style: ElevatedButton.styleFrom(
                                      minimumSize: Size.fromHeight(50)),
                                  label: Text('Open url'),
                                )
                              : type == 'contact'
                                  ? ElevatedButton.icon(
                                      onPressed: () {},
                                      icon: Icon(Icons.open_in_new),
                                      style: ElevatedButton.styleFrom(
                                          minimumSize: Size.fromHeight(50)),
                                      label: Text('Save Contact'),
                                    )
                                  : Container(),
                          SizedBox(
                            height: 16,
                          ),
                          Row(
                            children: [
                              Expanded(
                                  child: OutlinedButton.icon(
                                      onPressed: () {
                                        Share.share(data);
                                      },
                                      icon: Icon(Icons.share),
                                      label: Text('Share'))),
                              Expanded(
                                  child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        scannerController.start();
                                      },
                                      icon: Icon(Icons.qr_code_scanner),
                                      label: Text('Scan Again'))),
                            ],
                          )
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ));
  }

  Future<void> _launcherUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _saveContact(String vcardData) async {
    final lines = vcardData.split('\n');
    String? name, phone, email;
    for (var line in lines) {
      if (line.startsWith('FN:')) name = line.substring(3);
      if (line.startsWith('TEL:')) phone = line.substring(4);
      if (line.startsWith('EMAIL:')) email = line.substring(5);
    }
    final contact = contacts.Contact()
      ..name.first = name ?? ''
      ..phones = [contacts.Phone(phone ?? '')]
      ..emails = [contacts.Email(email ?? '')];
    try {
      await contact.insert();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Cantact Saved!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Scan'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                height: 350,
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      ElevatedButton(
                        onPressed: _checkPermission,
                        child: Text('Grant permission'),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('Scan QR code'),
          actions: [
            IconButton(
                onPressed: () {
                  setState(() {
                    isFlashOn = !isFlashOn;
                    scannerController.toggleTorch();
                  });
                },
                icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off))
          ],
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: scannerController,
              onDetect: (capture) {
                final barcode = capture.barcodes.first;
                if (barcode.rawValue != null) {
                  final String code = barcode.rawValue!;
                  _processScannedData(code);
                }
              },
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
              child: Text('Align Qr Code within the frame'),

            ))
          ],
        ),
      );
    }
  }
}
