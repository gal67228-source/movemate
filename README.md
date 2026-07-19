# MoveMate v0.2.0

גרסת 0.2 מוסיפה ניהול משימות מלא ושמירה מקומית.

## יכולות

- שמירת פרטי המעבר במכשיר
- פתיחה ישירה של ה-Dashboard לאחר יצירת מעבר
- יצירת משימות אוטומטיות לפי תאריך המעבר
- הוספה, עריכה, מחיקה והשלמה של משימות
- חיפוש והסתרת משימות שהושלמו
- קטגוריה, עדיפות ותאריך יעד
- Dashboard עם נתונים ואחוזי התקדמות אמיתיים
- עבודה ללא אינטרנט

## אחסון

הגרסה משתמשת ב-SharedPreferences עם JSON מאחורי Repository. המבנה מאפשר מעבר עתידי ל-Drift/SQLite בלי לשנות את שכבת הממשק.

## CI

GitHub Actions מריץ format, analyze, tests ובניית APK מסוג release.

## Version 0.3.0

- Automatic room list based on the move setup
- Add and remove rooms
- Packing inventory with room, destination and packed status
- Numbered moving boxes with contents, fragile flag and closed status
- Live packing progress on the dashboard

## גרסה 0.4.0 — Smart Box Manager

- יצירה ועריכה של ארגזים
- חיפוש לפי מספר, חדר, שם או תכולה
- סטטוסים מהכנה ועד פריקה
- סימון משקל ותכולה שבירה
- הערות ותאריכי אריזה/פריקה
- תאימות לארגזים שנשמרו בגרסאות קודמות

## Sale Manager (v0.5)

The Sales feature stores asking and sold prices as whole integer shekels, supports status/category filtering, and loads legacy sale JSON fields without deleting existing local data.


## v0.7.0 Smart Rooms
Room equipment catalogs, custom items, quick removal, explicit item editing, and synchronized box contents.


## v0.9 Moving Day

The Moving Day screen brings together box loading and arrival status, urgent tasks, and a persistent checklist for important personal items.


## v0.95 Polish Release

Version 0.95 focuses on consistent Material 3 styling, accessibility, upgrade safety, QA documentation, and release artifacts. GitHub Actions produces both an APK and an AAB. See `docs/QA_CHECKLIST.md` before promoting the project to v1.0.

## v0.96 Settings

- Three-dot overflow menu on the dashboard
- Editable move name, addresses, and date
- Persistent system, light, and dark appearance modes
- About screen with the installed version


## v0.98 authentication

MoveMate now supports a Google identity layer while remaining offline-first. Without Firebase configuration, the app continues to work in local mode. See `docs/FIREBASE_SETUP.md` for the one-time Firebase and GitHub Actions setup.

## QR codes

MoveMate supports QR generation and scanning for boxes. Photo storage is intentionally not included so the app can remain free to operate.
