import 'package:flutter/cupertino.dart';
import '../../widgets/home/tab_content_widget.dart';
import '../../widgets/common/search_bar_widget.dart';

class DiscountsScreen extends StatelessWidget {
  const DiscountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Ofertas'),
      ),
      child: Column(
        children: const [
          SearchBarWidget(placeholder: 'Buscar ofertas...'),
          Expanded(
            child: TabContentWidget(filter: 'discounts'),
          ),
        ],
      ),
    );
  }
}
