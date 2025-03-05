import 'dart:async';

/// Base abstract class for all BLoC classes
/// Implements basic dispose pattern
abstract class BlocBase {
  /// Cleanup resources
  void dispose();
}

/// Generic BLoC with stream controller
abstract class StreamBlocBase<T> extends BlocBase {
  final StreamController<T> _controller = StreamController<T>.broadcast();
  
  StreamController<T> get controller => _controller;
  Stream<T> get stream => _controller.stream;
  
  void add(T data) {
    if (!_controller.isClosed) {
      _controller.sink.add(data);
    }
  }
  
  @override
  void dispose() {
    _controller.close();
  }
}

/// Resource provider for BLoC
abstract class BlocProvider<T extends BlocBase> {
  final T bloc;
  final bool shouldDispose;
  
  BlocProvider(this.bloc, {this.shouldDispose = true});
  
  void dispose() {
    if (shouldDispose) {
      bloc.dispose();
    }
  }
}