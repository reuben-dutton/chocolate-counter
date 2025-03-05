import 'package:flutter/material.dart';
import 'package:food_inventory/common/bloc/bloc_base.dart';

/// Widget that provides BLoC to its children
class BlocProvider<T extends BlocBase> extends StatefulWidget {
  final T bloc;
  final Widget child;
  final bool dispose;

  const BlocProvider({
    Key? key,
    required this.bloc,
    required this.child,
    this.dispose = true,
  }) : super(key: key);

  @override
  _BlocProviderState<T> createState() => _BlocProviderState<T>();

  /// Static method to get the BLoC from context
  static T of<T extends BlocBase>(BuildContext context) {
    final provider = context.findAncestorWidgetOfExactType<BlocProvider<T>>();
    if (provider == null) {
      throw Exception('BlocProvider not found in widget tree');
    }
    return provider.bloc;
  }
}

class _BlocProviderState<T extends BlocBase> extends State<BlocProvider<T>> {
  @override
  void dispose() {
    if (widget.dispose) {
      widget.bloc.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Multiple BLoC provider widget
class MultiBlocProvider extends StatelessWidget {
  final List<BlocProvider> providers;
  final Widget child;

  const MultiBlocProvider({
    Key? key,
    required this.providers,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget current = child;
    for (int i = providers.length - 1; i >= 0; i--) {
      current = providers[i];
    }
    return current;
  }
}