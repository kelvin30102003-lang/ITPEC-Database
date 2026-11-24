import type { ReactNode } from "react";
import { adminNavigation } from "@/config/navigation";
import Link from "next/link";

export default function AdminLayout({ children }: { children: ReactNode }) {
  return <div className="mx-auto flex w-full max-w-6xl flex-1 flex-col gap-6 px-6 py-8 sm:px-10 lg:flex-row"><aside aria-label="Administration navigation" className="w-full shrink-0 rounded-xl border border-slate-200 bg-white p-3 lg:w-60"><nav className="grid gap-1">{adminNavigation.map(({ href, labelKey }) => <Link className="rounded-md px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50" href={href} key={href}>{labelKey.replace("nav.", "")}</Link>)}</nav></aside><div className="min-w-0 flex-1">{children}</div></div>;
}
