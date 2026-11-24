import type { LucideIcon } from "lucide-react";
import { BookOpen, Bookmark, ChartNoAxesCombined, ClipboardList, GraduationCap, House, Info, LifeBuoy, ScrollText, Settings, Users } from "lucide-react";

export type NavigationItem = { href: string; labelKey: string; icon?: LucideIcon };

export const marketingNavigation: NavigationItem[] = [
  { href: "/about", labelKey: "nav.about", icon: Info },
  { href: "/knowledge", labelKey: "nav.knowledge", icon: BookOpen },
  { href: "/support", labelKey: "nav.support", icon: LifeBuoy },
];

export const studentNavigation: NavigationItem[] = [
  { href: "/dashboard", labelKey: "nav.dashboard", icon: House },
  { href: "/dashboard/practice", labelKey: "nav.practice", icon: ClipboardList },
  { href: "/dashboard/mock-exam", labelKey: "nav.mockExam", icon: GraduationCap },
  { href: "/dashboard/learning", labelKey: "nav.learning", icon: BookOpen },
  { href: "/dashboard/bookmarks", labelKey: "nav.bookmarks", icon: Bookmark },
  { href: "/dashboard/history", labelKey: "nav.history", icon: ScrollText },
  { href: "/dashboard/profile", labelKey: "nav.profile", icon: Settings },
];

export const adminNavigation: NavigationItem[] = [
  { href: "/admin/dashboard", labelKey: "nav.adminDashboard", icon: ChartNoAxesCombined },
  { href: "/admin/questions", labelKey: "nav.questions", icon: ClipboardList },
  { href: "/admin/exams", labelKey: "nav.exams", icon: GraduationCap },
  { href: "/admin/categories", labelKey: "nav.categories", icon: BookOpen },
  { href: "/admin/articles", labelKey: "nav.articles", icon: ScrollText },
  { href: "/admin/donations", labelKey: "nav.donations", icon: LifeBuoy },
  { href: "/admin/users", labelKey: "nav.users", icon: Users },
];
