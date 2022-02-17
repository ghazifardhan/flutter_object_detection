import 'dart:developer';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:object_detection/blocs/camera_bloc.dart';
import 'package:object_detection/blocs/object_detection_state.dart';
import 'package:object_detection/image_classification/classifier.dart';
import 'package:object_detection/image_classification/classifier_float.dart';
import 'package:object_detection/image_classification/classifier_quant.dart';
import 'package:object_detection/main.dart';
import 'package:object_detection/utils/image_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:image/image.dart' as imageLib;

class ObjectDetectionBloc extends Cubit<ObjectDetectionState> {
  ObjectDetectionBloc() : super(ObjectDetectionUnloadState());

  final _picker = ImagePicker();
  int _counter = 0;
  late Interpreter _interpreter;
  Interpreter get interpreter => _interpreter;
  List<String>? _labels;
  List<String>? get labels => _labels;
  late List<List<int>> _outputShapes;
  late List<TfLiteType> _outputTypes;
  late TensorImage _inputImage;

  bool predicting = false;

  late Classifier _classifier;
  Classifier get classifier => _classifier;
  Category? _pred;
  Category? get pred => _pred;
  File? _file;
  File? get file => _file;
  late TfLiteType _inputType;
  late TfLiteType _outputType;
  late List<int> _inputShape;
  late List<int> _outputShape;
  late TensorBuffer _outputBuffer;
  late var _probabilityProcessor;

  Future<void> init() async {
    _classifier = ClassifierFloat();
    return emit(ObjectDetectionLoadedState(_counter++));
  }

  Future<void> openCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front
    );
    if (photo != null) {
      _file = File(photo.path);
      emit(ObjectDetectionLoadedState(_counter++));
      await _predict(File(photo.path));
    }
    
  }

  Future<void> _predict(File? fl) async {
    imageLib.Image imageInput = imageLib.decodeImage(fl!.readAsBytesSync())!;
    _pred = _classifier.predict(imageInput);
    emit(ObjectDetectionLoadedState(_counter++));
  }


  Future<void> initModelAndLabels() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'tflite/detect.tflite',
        options: InterpreterOptions()..threads = 1
      );
      _labels = await FileUtil.loadLabels('assets/tflite/labels.txt');

      // var outputTensors = _interpreter!.getOutputTensors();
      // _outputShapes = [];
      // _outputTypes = [];

      _inputShape = interpreter.getInputTensor(0).shape;
      _outputShape = interpreter.getOutputTensor(0).shape;
      _inputType = _interpreter.getInputTensor(0).type;
      _outputType = _interpreter.getOutputTensor(0).type;

      // for (var element in outputTensors) { 
      //   _outputShapes.add(element.shape);
      //   _outputTypes.add(element.type);
      // }

      _outputBuffer = TensorBuffer.createFixedSize(_outputShape, _outputType);
      _probabilityProcessor = TensorProcessorBuilder().add(NormalizeOp(0, 1)).build();

      navigatorKey.currentContext?.read<CameraBloc>().initCamera();

      emit(ObjectDetectionLoadedState(_counter++));
    } catch (e) {
      print("asdasd_e $e");
      emit(ObjectDetectionErrorState());
    }
  }

  Future<void> cameraStream(CameraController cameraController) async {
    // cameraController.initialize().then((_) async {
    //   await cameraController.startImageStream((CameraImage cameraImage) {
    //     if (interpreter != null && labels != null) {
    //       if (predicting) {
    //         return;
    //       }

    //       predicting = true;

    //       // convert cameraimage
    //       imageLib.Image? image = ImageUtils.convertCameraImage(cameraImage);

    //       print("asdasd_ $image");

    //       emit(ObjectDetectionLoadedState(_counter++));
    //     }  
    //   });
    // });
  }

  void predict(imageLib.Image image) {
    _inputImage = TensorImage.fromImage(image);
    // _inputImage.loadImage(image);
    // _inputImage = getProcessedImage(_inputImage);

    // print("asdasd_ ${_inputImage.height} ${_inputImage.width} ${_inputShape[1]} ${_inputShape[2]}");
    // interpreter.run(_inputImage.buffer, _outputBuffer.getBuffer());
  }

  /// Pre-process the image
  TensorImage getProcessedImage(TensorImage inputImage) {
    final padSize = max(inputImage.height, inputImage.width);

    // create ImageProcessor
    final imageProcessor = ImageProcessorBuilder()
      .add(ResizeWithCropOrPadOp(padSize, padSize))
      .add(ResizeOp(300, 300, ResizeMethod.BILINEAR))
      .build();

    inputImage = imageProcessor.process(inputImage);
    return inputImage;
  }

  TensorImage _preProcess() {
    int cropSize = max(_inputImage.height, _inputImage.width);
    var imageProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(cropSize, cropSize))
        .add(ResizeOp(300, _inputShape[2], ResizeMethod.BILINEAR))
        // .add(NormalizeOp(127.5, 127.5))
        .build();

    _inputImage = imageProcessor.process(_inputImage);
    return _inputImage;
  }

}