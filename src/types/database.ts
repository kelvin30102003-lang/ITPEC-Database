/** Existing `todos` type is retained for the current dashboard query. Regenerate complete schema types after the SQL migration is applied. */
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
    Functions: {
      grade_exam_attempt: {
        Args: { p_attempt_id: string };
        Returns: undefined;
      };
      complete_practice_session: {
        Args: { p_session_id: string };
        Returns: undefined;
      };
    };
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};
