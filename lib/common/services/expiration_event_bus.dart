import 'dart:async';

/// A simple event bus for broadcasting expiration date change events
class ExpirationEventBus {
  // Singleton instance
  static final ExpirationEventBus _instance = ExpirationEventBus._internal();
  factory ExpirationEventBus() => _instance;
  ExpirationEventBus._internal();

  // Broadcast stream controller
  final _controller = StreamController<void>.broadcast();
  
  /// Stream that BLoCs can subscribe to
  Stream<void> get stream => _controller.stream;
  
  /// Emit an event when an expiration date changes
  void emitExpirationChanged() {
    _controller.add(null);
  }
  
  /// Clean up resources
  void dispose() {
    _controller.close();
  }
}