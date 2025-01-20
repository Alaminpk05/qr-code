import 'package:flutter/material.dart';
import 'package:qr_code/screens/create.dart';
import 'package:qr_code/screens/scan.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home'),
        ),
        body: Center(
          child: Column(
            children: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,MaterialPageRoute(builder: (c)=>ScanPage())
                    );
                  },
                  child: Text('QR code Scan')),
              ElevatedButton(onPressed: () {
                 Navigator.push(
                      context,MaterialPageRoute(builder: (c)=>Create())
                    );
              }, child: Text('QR code generate')),
            ],
          ),
        ),
      ),
    );
  }
}
