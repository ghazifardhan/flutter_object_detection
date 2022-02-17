import 'dart:isolate';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:object_detection/blocs/camera_state.dart';
import 'package:object_detection/blocs/object_detection_bloc.dart';
import 'package:object_detection/main.dart';
import 'package:object_detection/utils/image_utils.dart';
import 'package:image/image.dart' as img;
import 'package:object_detection/utils/isolate_utils.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class CameraBloc extends Cubit<CameraState> {
  CameraBloc() : super(CameraUnloadState());

  int _counter = 0;
  late CameraController _cameraController;
  CameraController get cameraController => _cameraController;

  img.Image? _image;
  img.Image? get image => _image;
  late TensorImage _inputImage;
  late IsolateUtils isolateUtils;

  Future<void> initCamera() async {
    
    isolateUtils = IsolateUtils();
    await isolateUtils.start();

    final interpreter = navigatorKey.currentContext!.read<ObjectDetectionBloc>().interpreter;
    final labels = navigatorKey.currentContext!.read<ObjectDetectionBloc>().labels;

    _cameraController = CameraController(cameras[1], ResolutionPreset.medium);
    await _cameraController.initialize().then((_) {
      _cameraController.startImageStream((image) async {
        // print('asdads_ ${image.format.group}');
        if (interpreter != null && labels != null) {
          var isolateData = IsolateData(image, interpreter.address, labels);
          Map<String, dynamic> inferenceResults = await inference(isolateData);
          print("asdasd_a $inferenceResults");
        }
      });
    });
    emit(CameraLoadedState(_counter++));
  }

  /// Runs inference in another isolate
  Future<Map<String, dynamic>> inference(IsolateData isolateData) async {
    ReceivePort responsePort = ReceivePort();
    isolateUtils
        .sendPort
        ?.send(isolateData..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    return results;
  }

  TensorImage _preProcess() {
    int cropSize = max(_inputImage.height, _inputImage.width);
    var imageProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(cropSize, cropSize))
        .add(ResizeOp(300, 300, ResizeMethod.BILINEAR))
        // .add(NormalizeOp(127.5, 127.5))
        .build();

    _inputImage = imageProcessor.process(_inputImage);
    return _inputImage;
  }
}