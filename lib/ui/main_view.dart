import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:object_detection/blocs/camera_bloc.dart';
import 'package:object_detection/blocs/camera_state.dart';
import 'package:object_detection/blocs/object_detection_bloc.dart';
import 'package:object_detection/blocs/object_detection_state.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MainViewState();
  }
}

class _MainViewState extends State<MainView> {

  @override
  void initState() {
    super.initState();
    // context.read<CameraBloc>().initCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Detection'),
      ),
      body: BlocConsumer<ObjectDetectionBloc, ObjectDetectionState>(
        listener: (context, odState) {
          if (odState is ObjectDetectionLoadedState) {

          }
        },
        builder: (context, odState) {
          if (odState is ObjectDetectionLoadedState) {
            return BlocConsumer<CameraBloc, CameraState>(
              listener: (context, state) {
                if (state is CameraLoadedState) {
                  final image = context.read<CameraBloc>().image;
                  if (image != null) {
                    context.read<ObjectDetectionBloc>().predict(image);
                  }
                }
              },
              builder: (context, state) {
                if (state is CameraLoadedState) {
                  final cameraController = context.read<CameraBloc>().cameraController;
                  return CameraPreview(cameraController);
                }
                return Container();
              }, 
            );
          }
          return Container();
        },
      ),
    );
  }

}