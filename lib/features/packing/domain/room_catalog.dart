class CatalogItem {
  const CatalogItem(this.name, {this.isLarge = false});
  final String name;
  final bool isLarge;
}

const roomCatalog = <String, List<CatalogItem>>{
  'מטבח': [
    CatalogItem('מקרר', isLarge: true), CatalogItem('מקפיא', isLarge: true),
    CatalogItem('תנור', isLarge: true), CatalogItem('כיריים'),
    CatalogItem('מדיח', isLarge: true), CatalogItem('מיקרוגל'),
    CatalogItem('מיקסר'), CatalogItem('מעבד מזון'), CatalogItem('קומקום'),
    CatalogItem('טוסטר'), CatalogItem('מכונת קפה'), CatalogItem('סירים'),
    CatalogItem('מחבתות'), CatalogItem('צלחות'), CatalogItem('כוסות'),
    CatalogItem('סכו״ם'), CatalogItem('קערות'), CatalogItem('כלי אפייה'),
  ],
  'סלון': [
    CatalogItem('ספה', isLarge: true), CatalogItem('טלוויזיה', isLarge: true),
    CatalogItem('מזנון', isLarge: true), CatalogItem('שולחן סלון', isLarge: true),
    CatalogItem('שטיח'), CatalogItem('רמקולים'), CatalogItem('עציצים'),
    CatalogItem('תמונות'), CatalogItem('וילונות'), CatalogItem('ספרים'),
  ],
  'חדר שינה': [
    CatalogItem('מיטה', isLarge: true), CatalogItem('מזרן', isLarge: true),
    CatalogItem('ארון', isLarge: true), CatalogItem('שידות', isLarge: true),
    CatalogItem('בגדים'), CatalogItem('מצעים'), CatalogItem('נעליים'),
    CatalogItem('מנורות'), CatalogItem('תכשיטים'),
  ],
  'חדר ילדים': [
    CatalogItem('מיטה', isLarge: true), CatalogItem('ארון', isLarge: true),
    CatalogItem('שולחן', isLarge: true), CatalogItem('כיסא'),
    CatalogItem('צעצועים'), CatalogItem('ספרים'), CatalogItem('בגדים'),
    CatalogItem('לגו'), CatalogItem('ציוד לימודי'),
  ],
  'אמבטיה': [
    CatalogItem('מגבות'), CatalogItem('מוצרי רחצה'), CatalogItem('תרופות'),
    CatalogItem('מייבש שיער'), CatalogItem('מכונת גילוח'), CatalogItem('כביסה'),
  ],
  'מחסן': [
    CatalogItem('אופניים', isLarge: true), CatalogItem('סולם', isLarge: true),
    CatalogItem('כלי עבודה'), CatalogItem('מקדחה'), CatalogItem('צבעים'),
    CatalogItem('ציוד קמפינג'), CatalogItem('קישוטים'),
  ],
  'חדר עבודה': [
    CatalogItem('שולחן', isLarge: true), CatalogItem('כיסא', isLarge: true),
    CatalogItem('מחשב'), CatalogItem('מסך'), CatalogItem('מדפסת'),
    CatalogItem('כבלים'), CatalogItem('מסמכים'), CatalogItem('ספרים'),
  ],
};

List<CatalogItem> catalogForRoom(String roomName) {
  final exact = roomCatalog[roomName];
  if (exact != null) return exact;
  if (roomName.contains('שינה')) return roomCatalog['חדר שינה']!;
  if (roomName.contains('ילד')) return roomCatalog['חדר ילדים']!;
  return const [];
}
