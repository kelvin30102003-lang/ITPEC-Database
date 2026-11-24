import Link from "next/link";

export default function NotFound() {
  return <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col items-start justify-center px-6 py-20"><p className="text-sm font-semibold text-teal-800">404</p><h1 className="mt-2 text-3xl font-bold">Page not found</h1><p className="mt-3 text-slate-600">The page you are looking for does not exist.</p><Link className="mt-6 font-semibold text-teal-800 underline" href="/">Return home</Link></main>;
}
