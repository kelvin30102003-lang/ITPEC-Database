/** Replace this starter shape with `supabase gen types typescript` output after schema work begins. */
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  public: {
    Tables: {
      todos: {
        Row: { id: string | number; name: string };
        Insert: { id?: string | number; name: string };
        Update: { id?: string | number; name?: string };
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};

