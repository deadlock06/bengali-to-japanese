# Google Play — Bhasago submission kit (D-040)

Everything here is ready to paste/upload. Assets in this folder:
- `play_icon_512.png` — app icon (512×512, Play requires exactly this)
- `feature_graphic_1024x500.png` — feature graphic (required)
- **Screenshots** — YOU must add 2–8 phone screenshots (Play requirement; I can't
  screenshot the CanvasKit app reliably). Take them on your phone from the
  installed APK: Home, AI Classroom, Vocabulary bank, a Mock exam, Progress.
  Min 320px, 16:9 or 9:16, PNG/JPG.

---

## App details
- **App name:** Bhasago — জাপানি শেখো
- **Default language:** Bengali (bn-BD)  ·  add English (en-US) as a second listing
- **App or game:** App  ·  **Category:** Education
- **Package name:** `com.bhasago.app`
- **Contact email:** marjukhasan825@gmail.com
- **Free / Paid:** Free (no IAP yet — declare "No" for in-app purchases)
- **Contains ads:** No

## Short description (≤80 chars)
```
বাংলায় জাপানি শেখো — অফলাইনে, JFT-Basic ও JLPT-এর জন্য।
```
English short:
```
Learn Japanese in Bengali — offline, built for JFT-Basic & JLPT.
```

## Full description (≤4000 chars)
```
Bhasago (ভাষাGO) বাংলাভাষীদের জন্য জাপানি শেখার একটা অফলাইন-ফার্স্ট অ্যাপ —
বিশেষ করে যারা SSW ভিসা, TITP বা JFT-Basic / JLPT পরীক্ষার প্রস্তুতি নিচ্ছে।

কেন আলাদা:
• পুরোপুরি বাংলায় — English-এর ফিল্টার ছাড়াই সরাসরি জাপানি বোঝো।
• অফলাইনে চলে — ইন্টারনেট ছাড়াই পুরো কোর্স, অডিও, রিভিউ সব কাজ করে।
• AI ক্লাসরুম — একজন সেনসেই ধাপে ধাপে শেখায়, প্রশ্ন করে, বুঝিয়ে দেয়।
• হিরাগানা ও কাতাকানা — ছবি-গল্পের কৌশলে (mnemonics) দ্রুত মুখস্থ, আঙুল দিয়ে
  লেখার অনুশীলন, নেটিভ উচ্চারণ সহ।
• স্মার্ট রিভিউ (FSRS) — যা ভুলে যাচ্ছ ঠিক সেই সময়েই মনে করিয়ে দেয়।
• শব্দভাণ্ডার — কোর্সের প্রতিটা শব্দ খুঁজে দেখো, শোনো, আয়ত্তে এসেছে কিনা দেখো।
• মক পরীক্ষা — আসল JLPT/JFT ফরম্যাটে অনুশীলন, সৎ স্কোর-অনুমান।
• রোলপ্লে — দোকান, ক্লিনিক, ইন্টারভিউর মতো বাস্তব পরিস্থিতিতে কথা বলার অনুশীলন।

নীতিমালা: কোনো চাপ নেই, কোনো লক নেই — যেকোনো সময় Skip/Hint/Quit। তোমার সব
ডেটা তোমার ফোনেই এনক্রিপ্ট করা; বিজ্ঞাপন নেই, ট্র্যাকিং নেই।

কোর্স: হিরাগানা/কাতাকানা → সংখ্যা-সময় → দৈনন্দিন ও কাজের ভাষা → JFT-Basic A2
→ JLPT N4 (N3/N2/N1 আসছে)।

জাপানে কাজ ও জীবনের জন্য তৈরি — গোমি বাছাই, কনবিনি, ক্লিনিক, বাসা ভাড়া,
ডাকঘর, ফোন — সব রোজকার দরকারি শব্দ।
```

## Data safety form (answers — matches privacy_screen.dart, all HONEST)
- **Does your app collect or share user data?** Yes (minimal).
- **Data collected:**
  - *App activity → learning progress:* collected, **only if the user enables
    cloud sync** (off by default). Stored anonymously (no name/email). Not shared
    with third parties. Encrypted in transit. User can request deletion.
  - *Messages the user types to the AI sensei:* processed by a third-party AI
    service **only when online** to generate a reply. Not linked to identity, not
    stored by the app. (Declare under "App info / other" → not for tracking.)
- **NOT collected:** name, email, phone, location, contacts, financial info,
  photos, files. No advertising ID. No analytics SDKs.
- **Data encrypted in transit:** Yes.
- **Users can request data deletion:** Yes (in-app: Settings → তোমার ডেটা, 1-tap
  delete with 7-day grace; also export).
- **Privacy policy URL:** REQUIRED — host `privacy_screen` content publicly (a
  GitHub Pages / any static page). See "Privacy policy" below.

## Content rating (questionnaire → will yield "Everyone / PEGI 3")
Education app; no violence, no user-to-user unmoderated content (the AI chat is
tutoring only), no gambling. Answer all "No".

## Target audience & content
- **Target age:** 18+ (adult learners / workers). This avoids the Families
  program requirements. If you want 13+, expect extra declarations.

## Signing
- Upload the **App Bundle**: `~/Downloads/bhasago-release.aab` (release-signed
  with your upload key, `com.bhasago.app`).
- **Enroll in Play App Signing** (Play manages the final signing key; you keep
  the *upload* key). Your upload keystore:
  `~/.bhasago-upload-keystore.jks` + `android/key.properties`.
  ⚠️ BACK BOTH UP SOMEWHERE SAFE. Lose them → you can never update this app.

## Privacy policy — quick host
Play requires a public URL. Fastest: enable GitHub Pages on the repo and add a
`privacy.html` (I can generate the HTML from the in-app policy on request), or
paste the policy into any free host. The content already exists in
`lib/presentation/privacy_screen.dart`.

---

## What only YOU can do (Play Console)
1. Create a **Google Play Developer account** ($25 one-time) at play.google.com/console.
2. Create the app → paste the details/descriptions above.
3. Upload `play_icon_512.png`, `feature_graphic_1024x500.png`, your screenshots.
4. Complete Data safety, Content rating, Target audience, Ads (No) forms above.
5. Add the privacy-policy URL.
6. **Release track:** start with **Internal testing** (instant, up to 100 testers,
   no review wait) or **Closed testing** → then Production. This lets you publish
   NOW and get real users without exposing unreviewed content publicly.
7. Upload `bhasago-release.aab`, roll out.

## Honest caveat (owner's call)
Content has NOT had native-speaker review (A5) yet. Publishing to **Internal /
Closed testing** first is the responsible way to go live now — real users, but
not the open public — while a reviewer checks the Japanese. Production release
before review risks shipping any content errors to everyone.
