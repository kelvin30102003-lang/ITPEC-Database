import Link from "next/link";
import { ArrowRight, BookOpenCheck, Languages } from "lucide-react";
import { APP_CONFIG } from "@/config/app";

export default function HomePage() {
  return (
    <main className="mx-auto flex w-full max-w-6xl flex-1 flex-col justify-center px-6 py-20 sm:px-10">
      <div className="mb-8 inline-flex w-fit items-center gap-2 rounded-full border border-teal-200 bg-teal-50 px-3 py-1.5 text-sm font-medium text-teal-800">
        <Languages aria-hidden="true" className="size-4" /> Myanmar + English
      </div>
      <h1 className="max-w-3xl text-4xl font-bold tracking-tight text-slate-950 sm:text-6xl">Learn ITPEC with clarity and confidence.</h1>
      <p className="mt-6 max-w-2xl text-lg leading-8 text-slate-600">A bilingual learning hub for practice, exam preparation, and trusted IT knowledge. Original ITPEC questions stay in their original language.</p>
      <div className="mt-9 flex flex-wrap gap-3">
        <Link className="inline-flex items-center gap-2 rounded-lg bg-teal-700 px-5 py-3 font-semibold text-white hover:bg-teal-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-teal-700" href="/dashboard/practice">Explore practice <ArrowRight aria-hidden="true" className="size-4" /></Link>
        <Link className="inline-flex items-center gap-2 rounded-lg border border-slate-300 px-5 py-3 font-semibold text-slate-800 hover:bg-slate-50" href="/knowledge"><BookOpenCheck aria-hidden="true" className="size-4" /> Browse knowledge</Link>
      </div>
      <p className="mt-16 text-sm text-slate-500">{APP_CONFIG.name} · Built for the ITPEC learning community</p>
    </main>
  );
}
