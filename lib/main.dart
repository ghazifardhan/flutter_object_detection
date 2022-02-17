import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:object_detection/blocs/camera_bloc.dart';
import 'package:object_detection/blocs/object_detection_bloc.dart';
import 'package:object_detection/blocs/object_detection_state.dart';
import 'package:object_detection/image_classification/classifier.dart';
import 'package:image/image.dart' as img;
import 'package:object_detection/image_classification/classifier_quant.dart';
import 'package:object_detection/ui/home_view.dart';
import 'package:object_detection/ui/main_view.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();
  BlocOverrides.runZoned(
    () => runApp(MultiBlocProvider(
    providers: [
      BlocProvider<CameraBloc>(create: (context) => CameraBloc()),
      BlocProvider<ObjectDetectionBloc>(create: (context) => ObjectDetectionBloc()..initModelAndLabels())
    ], 
    child: const MyApp()
  )));
}

class MyAppV2 extends StatelessWidget {
  const MyAppV2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Object Detection TFLite',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const MainView(),
      navigatorKey: navigatorKey,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: HomeView(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: BlocConsumer<ObjectDetectionBloc, ObjectDetectionState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state is ObjectDetectionLoadedState) {
            final file = context.read<ObjectDetectionBloc>().file;
            final pred = context.read<ObjectDetectionBloc>().pred;

            return Column(
              children: <Widget>[
                Center(
                  child: file == null
                      ? const Text('No image selected.')
                      : Container(
                          constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height / 2),
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          child: Image.file(file),
                        ),
                ),
                const SizedBox(
                  height: 36,
                ),
                Text(
                  pred != null ? pred.label : '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  pred != null
                      ? 'Confidence: ${pred.score.toStringAsFixed(3)}'
                      : '',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            );
          }
          return Container();
        }, 
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<ObjectDetectionBloc>().openCamera();
        },
        tooltip: 'Camera',
        child: const Icon(Icons.camera),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
