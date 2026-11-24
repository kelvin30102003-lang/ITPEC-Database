export const APP_CONFIG = {
  name: "ITPEC Hub",
  description: "A bilingual learning hub for ITPEC preparation.",
  defaultLanguage: "en",
  supportedLanguages: ["en", "my"],
} as const;

export type AppLanguage = (typeof APP_CONFIG.supportedLanguages)[number];
