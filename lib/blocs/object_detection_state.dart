import 'package:equatable/equatable.dart';

abstract class ObjectDetectionState extends Equatable {
  const ObjectDetectionState();

  @override
  List<Object> get props => [];
}

class ObjectDetectionUnloadState extends ObjectDetectionState {}
class ObjectDetectionLoadedState extends ObjectDetectionState {
  final int counter;
  const ObjectDetectionLoadedState(this.counter);

  @override
  List<Object> get props => [counter];
}
class ObjectDetectionErrorState extends ObjectDetectionState {}