import 'package:flutter/material.dart';

class BackgroundScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Color? overlayColor; // optional overlay color for readability

  const BackgroundScaffold({
    Key? key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.overlayColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // This extends the background behind the AppBar.
      backgroundColor: Colors.transparent,
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image container
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Optional overlay for better text contrast
          if (overlayColor != null)
            Container(
              color: overlayColor,
            ),
          // Main content
          body,
        ],
      ),
    );
  }
}
