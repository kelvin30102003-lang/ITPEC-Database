import { createClient } from "@/lib/supabase/server";

export async function getTodos() {
  const supabase = await createClient();
  const { data } = await supabase.from("todos").select("id, name");
  return data ?? [];
}
