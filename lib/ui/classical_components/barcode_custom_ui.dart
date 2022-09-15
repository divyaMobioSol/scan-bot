import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scanbot_sdk/barcode_scanning_data.dart';
import 'package:scanbot_sdk/classical_components/barcode_camera.dart';
import 'package:scanbot_sdk/classical_components/barcode_live_detection.dart';
import 'package:scanbot_sdk/classical_components/barcode_scanner_configuration.dart';
import 'package:scanbot_sdk/classical_components/camera_configuration.dart';
import 'package:scanbot_sdk/classical_components/classical_camera.dart';
import 'package:scanbot_sdk/common_data.dart';

import '../../main.dart';
import '../pages_widget.dart';


class BarcodeScannerWidget extends StatefulWidget {
  const BarcodeScannerWidget({Key? key}) : super(key: key);

  @override
  _BarcodeScannerWidgetState createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  
  final resultStream = StreamController<BarcodeScanningResult>();
  ScanbotCameraController? controller;
  late BarcodeCameraLiveDetector barcodeCameraDetector;
  bool permissionGranted = false;
  bool flashEnabled = true;
  bool flashAvailable = false;
  bool showProgressBar = false;
  bool licenseIsActive = true;

  _BarcodeScannerWidgetState() {
    barcodeCameraDetector = BarcodeCameraLiveDetector(
      
      barcodeListener: (scanningResult) {
   
        barcodeCameraDetector
            .pauseDetection(); 
        Navigator.pop(context, scanningResult);

        print(scanningResult.toJson().toString());
      },

      errorListener: (error) {
        setState(() {
          licenseIsActive = false;
        });
        Logger.root.severe(error.toString());
      },
    );
  }

  void checkPermission() async {
  
    final permissionResult = await [Permission.camera].request();
    setState(() {
      permissionGranted =
          permissionResult[Permission.camera]?.isGranted ?? false;
    });
  }

  @override
  void initState() {
    checkPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(),
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        title: const Text(
          'Scan barcodes',
          style: TextStyle(
            inherit: true,
            color: Colors.black,
          ),
        ),
        actions: [
          if (flashAvailable)
            IconButton(
                onPressed: () {
                  controller?.setFlashEnabled(!flashEnabled).then((value) => {
                        setState(() {
                          flashEnabled = !flashEnabled;
                        })
                      });
                },
                icon: Icon(flashEnabled ? Icons.flash_on : Icons.flash_off))
        ],
      ),
      body: Stack(
        children: <Widget>[
        
          licenseIsActive
              ? permissionGranted
                  ? BarcodeScannerCamera(
                      cameraDetector: barcodeCameraDetector,
                   
                      configuration: BarcodeCameraConfiguration(
                        flashEnabled: flashEnabled, 
                      
                        scannerConfiguration:
                            BarcodeClassicScannerConfiguration(
                          barcodeFormats: PredefinedBarcodes.allBarcodeTypes(),
                        
                          engineMode: EngineMode.NextGen,
                       
                        ),
                        finder: FinderConfiguration(
                            onFinderRectChange: (left, top, right, bottom) {
                           
                            },
                           
                            topWidget: const Center(
                                child: Text(
                              'Top hint text in centre',
                              style: TextStyle(color: Colors.white),
                            )),
                          
                            bottomWidget: const Align(
                                alignment: Alignment.topCenter,
                                child: Text(
                                  'This is text in finder bottom TopCenter  part',
                                  style: TextStyle(color: Colors.white),
                                )),
                         
                            widget: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 5,
                                      color: Colors.lightBlue.withAlpha(155),
                                    ),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20))),
                              ),
                            ),
                          
                            decoration: BoxDecoration(
                                border: Border.all(
                                  width: 5,
                                  color: Colors.deepPurple,
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(20))),
                            backgroundColor: Colors.amber.withAlpha(150),
                            finderAspectRatio:
                                const FinderAspectRatio(width: 5, height: 2)),
                      ),
                      onWidgetReady: (controller) {
                      
                        this.controller = controller;
                      
                        controller.isFlashAvailable().then((value) => {
                              setState(() {
                                flashAvailable = value;
                              })
                            });
                      },
                      onHeavyOperationProcessing: (show) {
                        showProgressBar = show;
                      },
                    )
                  : Container(
                      width: double.infinity,
                      height: double.infinity,
                      alignment: Alignment.center,
                      child: const Text(
                        'Permissions not granted',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
              : Container(
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
                  child: const Text(
                    'License is No more active',
                    style: TextStyle(fontSize: 16),
                  ),
                ),

          StreamBuilder<BarcodeScanningResult>(
              stream: resultStream.stream,
              builder: (context, snapshot) {
                if (snapshot.data == null) {
                  return Container();
                }

                Widget pageView;
                if (snapshot.data?.barcodeImageURI != null) {
                  if (shouldInitWithEncryption) {
                    pageView =
                        EncryptedPageWidget((snapshot.data?.barcodeImageURI)!);
                  } else {
                    pageView = PageWidget((snapshot.data?.barcodeImageURI)!);
                  }
                } else {
                  pageView = Container();
                }

                return Stack(
                  children: [
                    ListView.builder(
                        itemCount: snapshot.data?.barcodeItems.length ?? 0,
                        itemBuilder: (context, index) {
                          var barcode =
                              snapshot.data?.barcodeItems[index].text ?? '';
                          return Container(
                              color: Colors.white60, child: Text(barcode));
                        }),
                    (snapshot.data?.barcodeImageURI != null)
                        ? Container(
                            width: double.infinity,
                            height: double.infinity,
                            alignment: Alignment.bottomRight,
                            child: SizedBox(
                              width: 100,
                              height: 200,
                              child: pageView,
                            ),
                          )
                        : Container(),
                  ],
                );
              }),
          showProgressBar
              ? Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    child: const CircularProgressIndicator(
                      strokeWidth: 10,
                    ),
                  ),
                )
              : Container()
        ],
      ),
    );
  }
}
