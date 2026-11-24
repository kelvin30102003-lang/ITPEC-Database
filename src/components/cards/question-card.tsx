export function QuestionCard({ title, category, language }: { title: string; category: string; language: string }) {
  return <article className="rounded-xl border border-slate-200 bg-white p-5"><p className="text-xs font-semibold uppercase tracking-wide text-teal-800">{category} · {language}</p><h2 className="mt-2 font-semibold text-slate-900">{title}</h2></article>;
}
