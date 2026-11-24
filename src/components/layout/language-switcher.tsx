"use client";

import { useLanguage } from "@/components/providers/language-provider";

export function LanguageSwitcher() {
  const { language, setLanguage, t } = useLanguage();
  return <label className="flex items-center gap-2 text-sm text-slate-600"><span className="sr-only">{t("action.language")}</span><select aria-label={t("action.language")} className="rounded-md border border-slate-300 bg-white px-2 py-1.5" value={language} onChange={(event) => setLanguage(event.target.value as "en" | "my")}><option value="en">English</option><option value="my">မြန်မာ</option></select></label>;
}
