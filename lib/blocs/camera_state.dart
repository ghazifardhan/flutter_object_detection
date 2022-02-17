import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

abstract class CameraState extends Equatable {
  const CameraState();

  @override
  List<Object> get props => [];
}

class CameraUnloadState extends CameraState {}
class CameraLoadedState extends CameraState {
  final int counter;
  const CameraLoadedState(this.counter);
  @override
  List<Object> get props => [counter];
}
class CameraErrorState extends CameraState {}