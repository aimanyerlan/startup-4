import 'package:flutter/material.dart';

/// A simple layout wrapper for pages that don't use bottom navigation.
class Layout extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final bool showNav;

  const Layout({
    super.key,
    required this.child,
    this.appBar,
    this.showNav = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: appBar,
      body: SafeArea(
        child: child,
      ),
    );
  }
}
