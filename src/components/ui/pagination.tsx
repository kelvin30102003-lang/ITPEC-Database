import { Button } from "./button";

export function Pagination({ page, pageCount, onPageChange }: { page: number; pageCount: number; onPageChange: (page: number) => void }) {
  return <nav aria-label="Pagination" className="flex items-center justify-between"><Button variant="outline" disabled={page <= 1} onClick={() => onPageChange(page - 1)}>Previous</Button><span aria-live="polite" className="text-sm text-slate-600">Page {page} of {pageCount}</span><Button variant="outline" disabled={page >= pageCount} onClick={() => onPageChange(page + 1)}>Next</Button></nav>;
}
