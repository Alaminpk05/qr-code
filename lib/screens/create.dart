import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class Create extends StatefulWidget {
  const Create({super.key});

  @override
  State<Create> createState() => _CreateState();
}

class _CreateState extends State<Create> {
  final TextEditingController _textEditingController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();
  String qrData = '';
  String slectedType = 'text';
  final Map<String, TextEditingController> _controller = {
    'name': TextEditingController(),
    'phone': TextEditingController(),
    'email': TextEditingController(),
    'url': TextEditingController(),
  };

  String _generateQRData() {
    switch (slectedType) {
      case 'contact':
        return '''BEGIN:VCARD
        VERSION:3.0
        FN:${_controller['name']?.text}
        TEL:${_controller['phone']?.text}
        EMAIL:${_controller['email']?.text}
        END:VCARD''';

      case 'url':
        String url = _controller['url']?.text ?? '';
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          url = 'https://$url';
        }
        return url;
      default:
        return _textEditingController.text;
    }
  }

  Future<void> _shareQRcode() async {
    final directory = await getApplicationCacheDirectory();
    final imagePath = '${directory.path}/qr_code.png';
    final capture = await _screenshotController.capture();
    if (capture == null) return;
    File imageFile = File(imagePath);
    await imageFile.writeAsBytes(capture);
    await Share.shareXFiles([XFile(imagePath)], text: 'Share QR Code');
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            )),
        onChanged: (_) {
          setState(() {
            qrData = _generateQRData();
          });
        },
      ),
    );
  }

  Widget _buildInputFields() {
    switch (slectedType) {
      case 'contact':
        return Column(
          children: [
            _buildTextField(_controller['name']!, "Name"),
            _buildTextField(_controller['phone']!, "Phone"),
            _buildTextField(_controller['email']!, "Email"),
          ],
        );

      case 'url':
        return _buildTextField(_controller['url']!, "URL");
      default:
        return TextField(
          controller: _textEditingController,
          decoration: InputDecoration(
              labelText: 'Enter Text',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              )),
          onChanged: (value) {
            setState(() {
              qrData = value;
            });
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate QR Code'),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                            value: 'text',
                            label: Text('Text'),
                            icon: Icon(Icons.text_fields)),
                        ButtonSegment(
                            value: 'url',
                            label: Text('URL'),
                            icon: Icon(Icons.link)),
                        ButtonSegment(
                            value: 'contact',
                            label: Text('Contact'),
                            icon: Icon(Icons.contact_page)),
                      ],
                      selected: {slectedType},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() {
                          slectedType = selection.first;
                          qrData = '';
                        });
                      },
                    ),
                    SizedBox(height: 24,),
                    _buildInputFields(),
                  ]),
                ),
              ),
              SizedBox(height: 24,),
              
                qrData.isNotEmpty? Column(children: [
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)
                    ),
                  child: Padding(padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Screenshot(controller: _screenshotController, child:
                       Container(
                         color: Colors.white,
                         padding: EdgeInsets.all(16),
                         child: QrImageView(data: qrData,
                         version: QrVersions.auto,
                         size: 200,
                         errorCorrectionLevel: QrErrorCorrectLevel.H,
                         ),
                         
                       ))
                    ],
                  ),
                  
                  ),
                  ),
                  
                ],):Container(),

                ElevatedButton(onPressed: _shareQRcode,
                 child: Text('Share QR code'))
              
            ],
          ),
        ),
      ),
    );
  }
}
