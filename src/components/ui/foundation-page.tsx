import { PageHeader } from "./page-header";
import { EmptyState } from "./state-panels";

export function FoundationPage({ title, description }: { title: string; description?: string }) {
  return <main className="mx-auto w-full max-w-6xl flex-1 px-6 py-12 sm:px-10"><PageHeader title={title} description={description} /><EmptyState title="Foundation ready" description="This route is ready for its feature module. Product functionality will be added in a later phase." /></main>;
}
