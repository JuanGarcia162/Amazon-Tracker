import 'package:flutter/cupertino.dart';
import '../../widgets/home/tab_content_widget.dart';
import '../../widgets/common/search_bar_widget.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Explorar Productos'),
      ),
      child: Column(
        children: const [
          SearchBarWidget(placeholder: 'Buscar en explorar...'),
          Expanded(
            child: TabContentWidget(filter: 'explore'),
          ),
        ],
      ),
    );
  }
}
