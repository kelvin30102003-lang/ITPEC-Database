export const translations = {
  en: {
    "nav.about": "About", "nav.knowledge": "Knowledge base", "nav.support": "Support", "nav.dashboard": "Dashboard",
    "nav.practice": "Practice", "nav.mockExam": "Mock exam", "nav.learning": "Learning", "nav.bookmarks": "Bookmarks",
    "nav.history": "History", "nav.profile": "Profile", "nav.adminDashboard": "Admin dashboard", "nav.questions": "Questions",
    "nav.exams": "Exams", "nav.categories": "Categories", "nav.articles": "Articles", "nav.donations": "Donations", "nav.users": "Users",
    "action.login": "Log in", "action.register": "Get started", "action.language": "Language", "state.loading": "Loading…",
    "state.error": "Something went wrong.", "state.empty": "Nothing here yet.", "state.retry": "Try again", "state.search": "Search",
    "state.previous": "Previous", "state.next": "Next", "state.confirm": "Confirm", "state.cancel": "Cancel",
  },
  my: {
    "nav.about": "အကြောင်း", "nav.knowledge": "ဗဟုသုတ", "nav.support": "အကူအညီ", "nav.dashboard": "Dashboard",
    "nav.practice": "လေ့ကျင့်ရန်", "nav.mockExam": "အစမ်းစာမေးပွဲ", "nav.learning": "သင်ယူမှု", "nav.bookmarks": "မှတ်သားထားသည်များ",
    "nav.history": "မှတ်တမ်း", "nav.profile": "ကိုယ်ရေးအချက်အလက်", "nav.adminDashboard": "Admin dashboard", "nav.questions": "မေးခွန်းများ",
    "nav.exams": "စာမေးပွဲများ", "nav.categories": "အမျိုးအစားများ", "nav.articles": "ဆောင်းပါးများ", "nav.donations": "လှူဒါန်းမှုများ", "nav.users": "အသုံးပြုသူများ",
    "action.login": "ဝင်ရောက်ရန်", "action.register": "စတင်ရန်", "action.language": "ဘာသာစကား", "state.loading": "ဖွင့်နေသည်…",
    "state.error": "တစ်စုံတစ်ခု မှားယွင်းသွားသည်။", "state.empty": "အချက်အလက် မရှိသေးပါ။", "state.retry": "ထပ်မံကြိုးစားရန်", "state.search": "ရှာဖွေရန်",
    "state.previous": "ယခင်", "state.next": "နောက်တစ်ခု", "state.confirm": "အတည်ပြုရန်", "state.cancel": "မလုပ်တော့ပါ",
  },
} as const;

export type TranslationKey = keyof typeof translations.en;
