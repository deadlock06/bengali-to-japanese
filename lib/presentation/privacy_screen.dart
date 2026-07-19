// Privacy policy (E1) — Bengali-first, plain language, and HONEST: it states
// exactly what the app does today, no more. Update this screen whenever data
// practices change (docs/07 sync contract, 00 §5 data autonomy).
import 'package:flutter/material.dart';

import '../app/theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: BhasagoTheme.bg,
      appBar: AppBar(title: const Text('গোপনীয়তা · Privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('তোমার ডেটা তোমার — সোজা কথায়', style: text.titleLarge),
          const SizedBox(height: 14),
          const _P('📱', 'সব শেখার ডেটা তোমার ফোনেই থাকে',
              'তোমার প্রগ্রেস, রিভিউ হিস্টরি, সেটিংস — সব এই ডিভাইসে, '
              'এনক্রিপ্ট করা (AES-256)। অ্যাকাউন্ট খোলা লাগে না, ফোন নম্বর বা '
              'ইমেইল চাই না।'),
          const _P('☁️', 'ক্লাউড ব্যাকআপ — শুধু তুমি চালু করলে',
              'Settings-এ sync চালু করলে তোমার প্রগ্রেসের একটা কপি নিরাপদ '
              'সার্ভারে (Supabase) যায় — বেনামে (anonymous), নাম-পরিচয় ছাড়া। '
              'বন্ধ রাখলে কিছুই যায় না। অ্যাপ পুরোটাই অফলাইনে চলে।'),
          const _P('🤖', 'AI সেনসেই — প্রশ্নটুকুই যায়, তাও অনলাইনে',
              'তুমি সেনসেইকে কিছু জিজ্ঞেস করলে সেই প্রশ্নের টেক্সট AI '
              'সার্ভিসে (Claude/Gemini/GPT জাতীয়) পাঠানো হয় উত্তর আনতে — '
              'শুধু অনলাইন থাকলে। তোমার প্রগ্রেস বা পরিচয় পাঠানো হয় না। '
              'অফলাইনে সেনসেই শুধু verified কনটেন্ট থেকে বলে।'),
          const _P('🎙️', 'ভয়েস — ফোনের নিজের recognizer',
              'কথা বলার ফিচারগুলো তোমার ফোনের বিল্ট-ইন স্পিচ রেকগনাইজার '
              'ব্যবহার করে। অ্যাপ কোনো রেকর্ডিং জমা রাখে না।'),
          const _P('📤', 'এক ট্যাপে সব নাও, এক ট্যাপে সব মুছো',
              'Settings → তোমার ডেটা: পুরো ডেটা ZIP করে নামাও যখন খুশি। '
              'ডিলিট চাইলে সাথে সাথে মুছে যায় — ৭ দিনের মধ্যে মত বদলালে '
              'ফেরত আনা যায়, তারপর চিরতরে গায়েব।'),
          const _P('🚫', 'যা আমরা করি না',
              'বিজ্ঞাপন নেই। ট্র্যাকিং নেই। analytics নেই। ডেটা বিক্রি নেই। '
              'দরকারই নেই — অ্যাপটা শেখানোর জন্য, তোমাকে বেচার জন্য না।'),
          const SizedBox(height: 18),
          Text(
            'শেষ আপডেট: ২০২৬-০৭-১৮ · ডেটা-চর্চা বদলালে এই পাতাটাই আগে বদলাবে।',
            style: text.bodySmall?.copyWith(color: BhasagoTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _P extends StatelessWidget {
  final String emoji, title, body;
  const _P(this.emoji, this.title, this.body);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                const SizedBox(height: 4),
                Text(body,
                    style: text.bodySmall
                        ?.copyWith(height: 1.55, color: BhasagoTheme.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
