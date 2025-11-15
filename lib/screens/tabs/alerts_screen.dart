import 'package:flutter/cupertino.dart';
import '../../widgets/home/tab_content_widget.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Alertas'),
      ),
      child: TabContentWidget(filter: 'alerts'),
    );
  }
}
