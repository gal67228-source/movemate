import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/features/search/domain/global_search_result.dart';

void main() {
  const results = [
    GlobalSearchResult(
      id: 'inventory_1',
      type: GlobalSearchType.inventory,
      title: 'קומקום',
      subtitle: 'מטבח · בארגז · ארגז 12',
      route: '/rooms/kitchen',
    ),
    GlobalSearchResult(
      id: 'box_1',
      type: GlobalSearchType.box,
      title: 'ארגז 12',
      subtitle: 'מטבח · נארז',
      details: 'קומקום, כוסות',
      route: '/boxes/edit?id=box_1',
    ),
    GlobalSearchResult(
      id: 'task_1',
      type: GlobalSearchType.task,
      title: 'להזמין מוביל',
      subtitle: 'הובלה · עדיפות גבוהה',
      route: '/tasks/edit?id=task_1',
    ),
  ];

  test('searches across titles, subtitles and details', () {
    expect(
      filterGlobalSearchResults(results: results, query: 'קומקום'),
      hasLength(2),
    );
    expect(
      filterGlobalSearchResults(results: results, query: 'מטבח 12'),
      hasLength(2),
    );
  });

  test('filters by result type', () {
    final filtered = filterGlobalSearchResults(
      results: results,
      query: 'קומקום',
      type: GlobalSearchType.box,
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.type, GlobalSearchType.box);
  });

  test('normalizes repeated whitespace and Hebrew punctuation', () {
    expect(normalizeSearchText('  ארגז   12  '), 'ארגז 12');
    expect(normalizeSearchText('סכו״ם'), 'סכו"ם');
  });
}
