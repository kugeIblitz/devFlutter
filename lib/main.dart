import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:face_camera/face_camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FaceCamera.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? _capturedImage;
  double faceX = 0.0;
  double faceY = 0.0;
  Uint8List? gifBytes;

  @override
  void initState() {
    super.initState();
    loadGifBytes();
  }

  Future<void> loadGifBytes() async {
    final ByteData data = await rootBundle.load('assets/images/head.gif');
    gifBytes = data.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FaceCamera example app'),
        ),
        body: Builder(builder: (context) {
          if (_capturedImage != null) {
            return Center(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Image.file(
                    _capturedImage!,
                    width: double.maxFinite,
                    fit: BoxFit.fitWidth,
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _capturedImage = null),
                    child: const Text(
                      'Capture Again',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          }
          return Stack(
            children: [
              SmartFaceCamera(
                autoCapture: true,
                defaultCameraLens: CameraLens.front,
                onCapture: (File? image) {
                  setState(() => _capturedImage = image);
                },
                onFaceDetected: (Face? face) {
                  if (face != null) {
                    setState(() {
                      faceX =
                          (face.boundingBox.left + face.boundingBox.right) / 2;
                      faceY =
                          (face.boundingBox.top + face.boundingBox.bottom) / 2;
                    });
                  }
                },
                messageBuilder: (context, face) {
                  if (face == null) {
                    return _message('Place your face in the camera');
                  }
                  if (!face.wellPositioned) {
                    return _message('Center your face in the square');
                  }
                  return _positionMessage('Face Position: X=$faceX, Y=$faceY');
                },
              ),
              // Add a dynamic image based on face position
              Positioned(
                top: faceY,
                left: faceX,
                child: _buildDynamicImage(),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _message(String msg) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 15),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      );

  Widget _positionMessage(String msg) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 15),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w700,
            color: Colors.green,
          ),
        ),
      );
  Widget _buildDynamicImage() {
    if (gifBytes != null) {
      // Determine which frame to display based on face position
      if (faceX > 0 && faceY > 0) {
        // Display a different frame when face is well-positioned
        return Image.memory(
          gifBytes!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        );
      } else {
        // Display a different frame when face is not well-positioned
        return Image.asset(
          'assets/images/head_placeholder.gif', // Update with your placeholder image path
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        );
      }
    } else {
      // Placeholder or fallback image
      return Image.asset(
        'assets/images/head.gif', // Update with your fallback image path
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    }
  }
}
