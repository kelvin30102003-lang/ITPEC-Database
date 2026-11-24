import { Suspense } from "react";
import { PageHeader } from "@/components/ui/page-header";
import { LoadingState } from "@/components/ui/state-panels";
import { getTodos } from "@/features/dashboard/services/get-todos";

export default function DashboardPage() {
  return (
    <main className="py-4">
      <PageHeader title="Dashboard" description="Your learning overview and saved tasks." />
      <Suspense fallback={<LoadingState />}>
        <TodosPanel />
      </Suspense>
    </main>
  );
}

async function TodosPanel() {
  const todos = await getTodos();

  return (
    <section aria-labelledby="todos-heading" className="rounded-xl border border-slate-200 bg-white p-6">
      <h2 className="text-lg font-semibold" id="todos-heading">Todos</h2>
      <ul className="mt-4 list-inside list-disc space-y-2 text-slate-700">
        {todos?.map((todo) => <li key={todo.id}>{todo.name}</li>)}
      </ul>
      {todos?.length === 0 && <p className="mt-3 text-sm text-slate-500">No todos yet.</p>}
    </section>
  );
}
