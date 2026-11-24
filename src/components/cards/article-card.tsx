import Link from "next/link";

export function ArticleCard({ title, summary, href }: { title: string; summary: string; href: string }) {
  return <article className="rounded-xl border border-slate-200 bg-white p-5"><h2 className="font-semibold text-slate-900"><Link className="hover:text-teal-800" href={href}>{title}</Link></h2><p className="mt-2 text-sm leading-6 text-slate-600">{summary}</p></article>;
}
