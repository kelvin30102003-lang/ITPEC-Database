import Link from "next/link";
import { APP_CONFIG } from "@/config/app";

export function Footer() {
  return <footer className="mt-auto border-t border-slate-200 bg-white"><div className="mx-auto flex max-w-6xl flex-col justify-between gap-3 px-6 py-6 text-sm text-slate-500 sm:flex-row sm:px-10"><span>{APP_CONFIG.name}</span><Link className="hover:text-teal-800" href="/support">Support</Link></div></footer>;
}
