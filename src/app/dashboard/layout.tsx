import type { ReactNode } from "react";
import { Sidebar } from "@/components/layout/sidebar";

export default function DashboardLayout({ children }: { children: ReactNode }) {
  return <div className="mx-auto flex w-full max-w-6xl flex-1 flex-col gap-6 px-6 py-8 sm:px-10 lg:flex-row"><Sidebar /><div className="min-w-0 flex-1">{children}</div></div>;
}
