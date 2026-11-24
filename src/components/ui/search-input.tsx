import { Search } from "lucide-react";

export function SearchInput({ label = "Search", ...props }: { label?: string } & React.InputHTMLAttributes<HTMLInputElement>) {
  return <label className="relative block"><span className="sr-only">{label}</span><Search aria-hidden="true" className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-slate-400" /><input className="w-full rounded-md border border-slate-300 bg-white py-2 pl-9 pr-3 text-sm outline-none focus:border-teal-700 focus:ring-2 focus:ring-teal-100" placeholder={label} {...props} /></label>;
}
