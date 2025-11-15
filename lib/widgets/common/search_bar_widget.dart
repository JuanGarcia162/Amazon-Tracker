import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../config/app_colors.dart';

/// Widget de barra de búsqueda para filtrar productos
class SearchBarWidget extends StatefulWidget {
  final String placeholder;
  
  const SearchBarWidget({
    super.key,
    this.placeholder = 'Buscar productos...',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize with current search query
    final provider = context.read<ProductProvider>();
    _searchController.text = provider.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final provider = context.read<ProductProvider>();
    provider.setSearchQuery(value);
  }

  void _clearSearch() {
    _searchController.clear();
    final provider = context.read<ProductProvider>();
    provider.clearSearch();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: CupertinoSearchTextField(
            controller: _searchController,
            focusNode: _focusNode,
            placeholder: widget.placeholder,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.resolveTextPrimary(context),
            ),
            placeholderStyle: TextStyle(
              fontSize: 16,
              color: AppColors.resolveTextTertiary(context),
            ),
            backgroundColor: AppColors.resolveSearchBackground(context),
            borderRadius: BorderRadius.circular(10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: Icon(
              CupertinoIcons.search,
              color: AppColors.resolveTextSecondary(context),
              size: 20,
            ),
            suffixIcon: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: AppColors.resolveTextSecondary(context),
              size: 20,
            ),
            onChanged: _onSearchChanged,
            onSuffixTap: _clearSearch,
          ),
        );
      },
    );
  }
}
