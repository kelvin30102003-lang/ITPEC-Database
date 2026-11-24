# Internationalization

The initial supported languages are English (`en`) and Myanmar (`my`). The supported-language list is centralized in `src/config/app.ts`; shared interface strings live in `src/lib/i18n/translations.ts`. `LanguageProvider` exposes the current language and translation function, while `LanguageSwitcher` persists the choice in a first-party cookie for one year.

Add new interface copy to every language dictionary and use translation keys in shared controls and navigation. Keep technical terms such as API, database, and query in English where that improves clarity in Myanmar explanations. Explanatory knowledge-base content may be localized, but original ITPEC questions must not be automatically translated or altered.
