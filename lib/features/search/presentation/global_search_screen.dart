import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/global_search_provider.dart';
import '../domain/global_search_result.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  GlobalSearchType? _selectedType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(globalSearchResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('חיפוש בכל המעבר')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'חפש פריט, ארגז, משימה, מכירה או קנייה',
              leading: const Icon(Icons.search_rounded),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    tooltip: 'נקה חיפוש',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: FilterChip(
                    label: const Text('הכול'),
                    selected: _selectedType == null,
                    onSelected: (_) => setState(() => _selectedType = null),
                  ),
                ),
                ...GlobalSearchType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: FilterChip(
                      avatar: Icon(type.icon, size: 18),
                      label: Text(type.label),
                      selected: _selectedType == type,
                      onSelected: (_) {
                        setState(() => _selectedType = type);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: resultsAsync.when(
              data: (allResults) {
                final results = filterGlobalSearchResults(
                  results: allResults,
                  query: _searchController.text,
                  type: _selectedType,
                );

                if (results.isEmpty) {
                  return _EmptySearch(query: _searchController.text);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(globalSearchResultsProvider);
                    await ref.read(globalSearchResultsProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(result.type.icon)),
                          title: Text(result.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(result.subtitle),
                              if (result.details.trim().isNotEmpty)
                                Text(
                                  result.details,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_left_rounded),
                          onTap: () => context.push(result.route),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48),
                      const SizedBox(height: 12),
                      Text('לא ניתן לטעון את החיפוש: $error'),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          ref.invalidate(globalSearchResultsProvider);
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('נסה שוב'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 56),
            const SizedBox(height: 12),
            Text(
              query.trim().isEmpty
                  ? 'אין עדיין נתונים לחיפוש'
                  : 'לא נמצאו תוצאות עבור “$query”',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'נסה שם מוצר, מספר ארגז, חדר, משימה או פריט קנייה.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
