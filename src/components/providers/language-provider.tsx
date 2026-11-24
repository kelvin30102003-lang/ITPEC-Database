"use client";

import { createContext, useCallback, useContext, useSyncExternalStore, type ReactNode } from "react";
import { APP_CONFIG, type AppLanguage } from "@/config/app";
import { translations, type TranslationKey } from "@/lib/i18n/translations";

type LanguageContextValue = { language: AppLanguage; setLanguage: (language: AppLanguage) => void; t: (key: TranslationKey) => string };
const LanguageContext = createContext<LanguageContextValue | null>(null);
const LANGUAGE_EVENT = "itpec-language-change";

function getLanguageSnapshot(): AppLanguage {
  const stored = document.cookie.split("; ").find((item) => item.startsWith("itpec-language="))?.split("=")[1];
  return APP_CONFIG.supportedLanguages.includes(stored as AppLanguage) ? stored as AppLanguage : APP_CONFIG.defaultLanguage;
}

function subscribeToLanguage(callback: () => void) {
  window.addEventListener(LANGUAGE_EVENT, callback);
  return () => window.removeEventListener(LANGUAGE_EVENT, callback);
}

export function LanguageProvider({ children }: { children: ReactNode }) {
  const language = useSyncExternalStore(subscribeToLanguage, getLanguageSnapshot, () => APP_CONFIG.defaultLanguage);
  const setLanguage = useCallback((next: AppLanguage) => {
    document.cookie = `itpec-language=${next}; Path=/; Max-Age=31536000; SameSite=Lax`;
    window.dispatchEvent(new Event(LANGUAGE_EVENT));
  }, []);
  const t = useCallback((key: TranslationKey) => translations[language][key], [language]);
  return <LanguageContext.Provider value={{ language, setLanguage, t }}>{children}</LanguageContext.Provider>;
}

export function useLanguage() {
  const context = useContext(LanguageContext);
  if (!context) throw new Error("useLanguage must be used within LanguageProvider");
  return context;
}
