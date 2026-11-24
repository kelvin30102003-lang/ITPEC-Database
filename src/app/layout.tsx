import type { Metadata } from "next";
import type { ReactNode } from "react";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { RootProviders } from "@/components/providers/root-providers";
import { MainNavigation } from "@/components/layout/main-navigation";
import { Footer } from "@/components/layout/footer";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: { default: "ITPEC Hub | Learn with clarity", template: "%s | ITPEC Hub" },
  description: "A bilingual Myanmar and English learning hub for ITPEC preparation.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="flex min-h-full flex-col">
        <RootProviders>
          <MainNavigation />
          {children}
          <Footer />
        </RootProviders>
      </body>
    </html>
  );
}
