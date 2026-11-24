"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { studentNavigation } from "@/config/navigation";
import { useLanguage } from "@/components/providers/language-provider";
import { cn } from "@/lib/utils";

export function Sidebar() {
  const pathname = usePathname();
  const { t } = useLanguage();
  return <aside aria-label="Dashboard navigation" className="w-full shrink-0 rounded-xl border border-slate-200 bg-white p-3 lg:w-60"><nav className="grid gap-1">{studentNavigation.map(({ href, labelKey, icon: Icon }) => <Link aria-current={pathname === href ? "page" : undefined} className={cn("flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium text-slate-600 hover:bg-slate-50", pathname === href && "bg-teal-50 text-teal-900")} href={href} key={href}>{Icon && <Icon aria-hidden="true" className="size-4" />}{t(labelKey as keyof typeof import("@/lib/i18n/translations").translations.en)}</Link>)}</nav></aside>;
}
