import "package:flutter/material.dart";
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/screens/splash_screen.dart';
import 'package:instagram_flutter/utils/global_variables.dart';
import 'package:provider/provider.dart';

class ResponsiveLayout extends StatefulWidget {
  final Widget mobileScreenLayout;
  final Widget webScreenLayout;
  const ResponsiveLayout(
      {Key? key,
      required this.mobileScreenLayout,
      required this.webScreenLayout})
      : super(key: key);

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  bool _isReady = false;
  @override
  void initState() {
    super.initState();
    addData();
  }

  addData() async {
    setState(() {
      _isReady = false;
    });
    UserProvider _userProvider = Provider.of(context, listen: false);
    await _userProvider.refreshUser();
    setState(() {
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (!_isReady) {
        // getting the user data
        return const SplashScreen();
      } else {
        if (constraints.maxWidth > webScreenSize) {
          //  web screen layout
          return widget.webScreenLayout;
        }
        // mobile screen layout
        return widget.mobileScreenLayout;
      }
    });
  }
}
