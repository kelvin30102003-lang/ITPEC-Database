"use client";

import { useState, type ReactNode } from "react";
import { Button } from "./button";

export function ConfirmationDialog({ trigger, title, description, onConfirm }: { trigger: ReactNode; title: string; description: string; onConfirm: () => void }) {
  const [open, setOpen] = useState(false);
  return <><span onClick={() => setOpen(true)}>{trigger}</span>{open && <div className="fixed inset-0 z-50 grid place-items-center bg-slate-950/40 p-4" role="presentation"><section aria-labelledby="confirm-title" aria-modal="true" className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl" role="dialog"><h2 className="text-lg font-semibold" id="confirm-title">{title}</h2><p className="mt-2 text-sm text-slate-600">{description}</p><div className="mt-6 flex justify-end gap-2"><Button variant="outline" onClick={() => setOpen(false)}>Cancel</Button><Button onClick={() => { onConfirm(); setOpen(false); }}>Confirm</Button></div></section></div>}</>;
}
