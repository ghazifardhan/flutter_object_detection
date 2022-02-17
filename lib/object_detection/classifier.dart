import 'dart:math';

import 'package:object_detection/object_detection/recognation.dart';
import 'package:object_detection/object_detection/stats.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:image/image.dart' as imageLib;
import 'package:flutter/cupertino.dart';

class Classifier {
  // Instance of Interpreter
  Interpreter? _interpreter;

  // Labels file loaded as list
  List<String>? _labels;

  static const String MODEL_FILE_NAME = 'tflite/best-train5000-fp16.tflite';
  static const String LABEL_FILE_NAME = 'assets/tflite/taisho.txt';

  // Shapes of output tensors
  late List<List<int>> _outputShapes;

  // Shapes of output tensors
  late List<TfLiteType> _outputTypes;

  /// Gets the interpreter instance
  Interpreter? get interpreter => _interpreter;

  /// Gets the loaded labels
  List<String>? get labels => _labels;

  // Input size of image (height = width = 300)
  static const int INPUT_SIZE = 300;

   /// Result score threshold
  static const double THRESHOLD = 0.5;
  
  /// [ImageProcessor] used to pre-process the image
  late ImageProcessor imageProcessor;

  // Padding the image to transform into square
  late int padSize;

  /// Number of results to show
  static const int NUM_RESULTS = 2;

  Classifier({
    Interpreter? interpreter,
    List<String>? labels
  }) {
    loadModel(interpreter: interpreter);
    loadLabels(labels: labels);
  }

  void loadModel({Interpreter? interpreter}) async {
    try {
      _interpreter = interpreter ?? await Interpreter.fromAsset(
        MODEL_FILE_NAME,
        options: InterpreterOptions()..threads = 1
      );

      var outputTensors = _interpreter!.getOutputTensors();
      _outputShapes = [];
      _outputTypes = [];

      for (var element in outputTensors) { 
        _outputShapes.add(element.shape);
        _outputTypes.add(element.type);
      }
    } catch (e) {
      print("Error while creating interpreter: $e");
    }
  }

  void loadLabels({List<String>? labels}) async {
    try {
      _labels = labels ?? await FileUtil.loadLabels(LABEL_FILE_NAME);
    } catch (e) {
      print("Error while loading labels: $e");
    }
  }

  /// Pre-process the image
  TensorImage getProcessedImage(TensorImage inputImage) {
    padSize = max(inputImage.height, inputImage.width);

    // create ImageProcessor
    imageProcessor = ImageProcessorBuilder()
      .add(ResizeWithCropOrPadOp(padSize, padSize))
      .add(ResizeOp(INPUT_SIZE, INPUT_SIZE, ResizeMethod.BILINEAR))
      .add(NormalizeOp(1, 255))
      .build();

    inputImage = imageProcessor.process(inputImage);
    return inputImage;
  }

  /// Runs object detection on the input image
  Map<String, dynamic>? predict(imageLib.Image image) {
    try {
      var predictStartTime = DateTime.now().millisecondsSinceEpoch;

      if (_interpreter == null) {
        print("Interpreter not initialized");
        return null;
      }

      var preProcessStart = DateTime.now().millisecondsSinceEpoch;

      // Create TensorImage from image
      TensorImage inputImage = TensorImage(TfLiteType.float32);
      inputImage.loadImage(image);

      // Create TensorImage from image
      // TensorImage inputImage = TensorImage.fromImage(image);

      // Pre-process TensorImage
      inputImage = getProcessedImage(inputImage);

      // Pre-process TensorImage
      // inputImage = getProcessedImage(inputImage);

      print("asdasd_ ${inputImage.height} ${inputImage.width}");

      var preProcessElapsedTime =
          DateTime.now().millisecondsSinceEpoch - preProcessStart;

      // TensorBuffers for output tensors
      TensorBuffer outputLocations = TensorBufferFloat(_outputShapes[0]);
      TensorBuffer outputClasses = TensorBufferFloat(_outputShapes[1]);
      TensorBuffer outputScores = TensorBufferFloat(_outputShapes[2]);
      TensorBuffer numLocations = TensorBufferFloat(_outputShapes[3]);

      // Inputs object for runForMultipleInputs
      // Use [TensorImage.buffer] or [TensorBuffer.buffer] to pass by reference
      List<Object> inputs = [inputImage.buffer];

      // Outputs map
      Map<int, Object> outputs = {
        0: outputLocations.buffer,
        1: outputClasses.buffer,
        2: outputScores.buffer,
        3: numLocations.buffer,
      };

      var inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;

      // run inference
      _interpreter?.runForMultipleInputs(inputs, outputs);

      var inferenceTimeElapsed =
          DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

      // Maximum number of results to show
      int resultsCount = min(NUM_RESULTS, numLocations.getIntValue(0));

      // Using labelOffset = 1 as ??? at index 0
      int labelOffset = 1;

      // Using bounding box utils for easy conversion of tensorbuffer to List<Rect>
      List<Rect> locations = BoundingBoxUtils.convert(
        tensor: outputLocations,
        valueIndex: [1, 300, 300, 3],
        boundingBoxAxis: 2,
        boundingBoxType: BoundingBoxType.BOUNDARIES,
        coordinateType: CoordinateType.RATIO,
        height: INPUT_SIZE,
        width: INPUT_SIZE,
      );

      List<Recognition> recognitions = [];

      for (int i = 0; i < resultsCount; i++) {
        // Prediction score
        var score = outputScores.getDoubleValue(i);

        // Label string
        var labelIndex = outputClasses.getIntValue(i) + labelOffset;
        var label = _labels?.elementAt(labelIndex);

        if (score > THRESHOLD) {
          // inverse of rect
          // [locations] corresponds to the image size 300 X 300
          // inverseTransformRect transforms it our [inputImage]
          Rect transformedRect = imageProcessor.inverseTransformRect(
              locations[i], image.height, image.width);

          recognitions.add(
            Recognition(i, label!, score, transformedRect),
          );
        }
      }

      var predictElapsedTime =
          DateTime.now().millisecondsSinceEpoch - predictStartTime;

      return {
        "recognitions": recognitions,
        "stats": Stats(
            totalPredictTime: predictElapsedTime,
            inferenceTime: inferenceTimeElapsed,
            preProcessingTime: preProcessElapsedTime,
            totalElapsedTime: 0)
      };
    } catch (e) {
      print("Error predict $e");
    }    
  }
}