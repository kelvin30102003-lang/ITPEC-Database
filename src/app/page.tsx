import { createClient } from "@/utils/supabase/server";

export default async function Home() {
  const supabase = await createClient();
  const { data: todos } = await supabase.from("todos").select();

  return (
    <main className="mx-auto w-full max-w-3xl p-8">
      <h1 className="mb-6 text-2xl font-semibold">Todos</h1>
      <ul className="list-inside list-disc space-y-2">
        {todos?.map((todo) => (
          <li key={todo.id}>{todo.name}</li>
        ))}
      </ul>
    </main>
  );
}
