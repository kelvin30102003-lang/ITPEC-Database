import type { ButtonHTMLAttributes } from "react";
import { cn } from "@/lib/utils";

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & { variant?: "primary" | "outline" | "ghost" };
export function Button({ className, variant = "primary", ...props }: ButtonProps) {
  const variants = { primary: "bg-teal-700 text-white hover:bg-teal-800", outline: "border border-slate-300 bg-white text-slate-800 hover:bg-slate-50", ghost: "text-slate-700 hover:bg-slate-100" };
  return <button className={cn("inline-flex items-center justify-center rounded-md px-4 py-2 text-sm font-semibold transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-teal-700 disabled:pointer-events-none disabled:opacity-50", variants[variant], className)} {...props} />;
}
