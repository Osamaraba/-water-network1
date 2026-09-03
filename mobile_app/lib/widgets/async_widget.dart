import 'package:flutter/material.dart';
import 'app_states.dart';

/// A wrapper widget that handles loading, error, and empty states
class AppAsyncWidget<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Widget Function(T data) builder;
  final String? loadingMessage;
  final String? emptyTitle;
  final String? emptySubtitle;
  final IconData emptyIcon;
  final String? errorTitle;

  const AppAsyncWidget({
    Key? key,
    required this.snapshot,
    required this.builder,
    this.loadingMessage,
    this.emptyTitle,
    this.emptySubtitle,
    this.emptyIcon = Icons.inbox,
    this.errorTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return AppLoadingIndicator(message: loadingMessage);
    }

    if (snapshot.hasError) {
      return AppErrorState(
        title: errorTitle ?? 'حدث خطأ',
        message: snapshot.error.toString(),
        actionLabel: 'إعادة المحاولة',
        onAction: () {},
      );
    }

    final data = snapshot.data;
    if (data == null) {
      return AppEmptyState(
        icon: emptyIcon,
        title: emptyTitle ?? 'لا توجد بيانات',
        subtitle: emptySubtitle,
      );
    }

    // Handle List types
    if (data is List && data.isEmpty) {
      return AppEmptyState(
        icon: emptyIcon,
        title: emptyTitle ?? 'لا توجد عناصر',
        subtitle: emptySubtitle,
      );
    }

    return builder(data);
  }
}

/// Extension for FutureBuilder-like patterns
class AppFutureWidget<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) builder;
  final Widget Function()? onLoading;
  final Widget Function(Object error)? onError;
  final String? loadingMessage;

  const AppFutureWidget({
    Key? key,
    required this.future,
    required this.builder,
    this.onLoading,
    this.onError,
    this.loadingMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (onLoading != null) return onLoading!();
          return AppLoadingIndicator(message: loadingMessage);
        }

        if (snapshot.hasError) {
          if (onError != null) return onError!(snapshot.error!);
          return AppErrorState(
            title: 'حدث خطأ',
            message: snapshot.error.toString(),
            actionLabel: 'إعادة المحاولة',
            onAction: () {},
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const AppEmptyState(
            icon: Icons.inbox,
            title: 'لا توجد بيانات',
          );
        }

        return builder(data);
      },
    );
  }
}
