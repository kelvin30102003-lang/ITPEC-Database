"use client";

import Link from "next/link";
import { APP_CONFIG } from "@/config/app";
import { marketingNavigation } from "@/config/navigation";
import { useLanguage } from "@/components/providers/language-provider";
import { LanguageSwitcher } from "./language-switcher";

export function MainNavigation() {
  const { t } = useLanguage();
  return <header className="border-b border-slate-200 bg-white"><nav aria-label="Main navigation" className="mx-auto flex max-w-6xl items-center justify-between gap-6 px-6 py-4 sm:px-10"><Link className="font-bold tracking-tight text-slate-950" href="/">{APP_CONFIG.name}</Link><div className="flex items-center gap-5"><div className="hidden items-center gap-5 sm:flex">{marketingNavigation.map((item) => <Link className="text-sm font-medium text-slate-600 hover:text-teal-800" href={item.href} key={item.href}>{t(item.labelKey as keyof typeof import("@/lib/i18n/translations").translations.en)}</Link>)}</div><LanguageSwitcher /><Link className="rounded-md bg-teal-700 px-3 py-2 text-sm font-semibold text-white hover:bg-teal-800" href="/login">{t("action.login")}</Link></div></nav></header>;
}
