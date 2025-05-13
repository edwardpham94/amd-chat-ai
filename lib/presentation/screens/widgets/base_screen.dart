import 'package:flutter/material.dart';
import 'app_sidebar.dart';

class BaseScreen extends StatefulWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool showBackButton;
  final bool isChatScreen;
  const BaseScreen({
    super.key,
    required this.body,
    required this.title,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.showBackButton = false,
    this.isChatScreen = false,
  });

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openEndDrawer() {
    _scaffoldKey.currentState!.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        leading:
            widget.isChatScreen
                ? null
                : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
        automaticallyImplyLeading: !widget.isChatScreen,
        actions: [
          // Add the sidebar button to the top-right
          IconButton(icon: const Icon(Icons.menu), onPressed: _openEndDrawer),
          ...(widget.actions ?? []),
        ],
      ),
      endDrawer: const AppSidebar(),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}
