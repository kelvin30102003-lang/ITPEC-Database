"use client";

import { useEffect } from "react";
import { Button } from "@/components/ui/button";

export default function GlobalError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => { console.error(error); }, [error]);
  return <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col items-start justify-center px-6 py-20"><h1 className="text-3xl font-bold">Something went wrong</h1><p className="mt-3 text-slate-600">Please try again. If the problem continues, contact support.</p><Button className="mt-6" onClick={reset}>Try again</Button></main>;
}
