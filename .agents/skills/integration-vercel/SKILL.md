---
name: integration-vercel
description: >-
  Vercel integration skill. Auto-activates whenever working with Vercel
  deployments, preview URLs, environment variables, serverless functions,
  edge functions, domain settings, build logs, or CI/CD pipelines on Vercel.
  Also activates on: vercel deploy, vercel build, vercel env, preview branch,
  production deployment, vercel CLI, Next.js deployment, serverless, edge
  runtime, vercel.json, build output, deployment URL, vercel project,
  SENSEI web dashboard, SENSEI admin panel, content delivery, web tooling.
---

# Vercel Integration Guide

## You have Vercel connected to Claude
The Vercel integration gives Claude live access to your deployments, logs,
and environment variables — Claude can check build status, debug failures,
and help configure projects without leaving the chat.

## How Claude uses this integration
Claude can:
- Check deployment status and build logs
- Help debug build failures
- Suggest `vercel.json` configuration
- Help manage environment variables
- Review edge function / serverless function code

## SENSEI — Vercel role
SENSEI is a **Flutter Android app** — Vercel is NOT the main app host.
Vercel may be used for:
- **Web admin/content dashboard** (if built — see 12_BUSINESS_GTM)
- **Content delivery API** (serving verified lesson pack updates)
- **Landing page** (marketing site)
- **Webhook receiver** (for Supabase → SENSEI push sync)

## Common Vercel patterns for SENSEI tooling
```javascript
// vercel.json — example for a content API
{
  "functions": {
    "api/content/*.js": {
      "maxDuration": 10,
      "memory": 256
    }
  },
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "s-maxage=3600" }
      ]
    }
  ]
}
```

## Environment variable conventions
```
# Public (NEXT_PUBLIC_* prefix for Next.js)
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...

# Private (server-only)
SUPABASE_SERVICE_ROLE_KEY=eyJ...
CONTENT_SIGNING_SECRET=...
```

## Deploy commands
```bash
vercel                    # deploy to preview
vercel --prod             # deploy to production
vercel env pull .env.local  # pull env vars locally
vercel logs               # stream live logs
```
