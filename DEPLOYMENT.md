# OmicVerse Deployment Guide

## Prerequisites

1. **GitHub Repository** with OmicVerse code pushed to `main` branch
2. **Supabase Project** (optional — demo mode works without it)

## Step 1: Configure GitHub Secrets

Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**

Add these secrets:
- `SUPABASE_URL` — Your Supabase project URL (e.g. `https://xxx.supabase.co`)
- `SUPABASE_ANON_KEY` — Your Supabase anon (public) key

> ⚠️ **DO NOT** add the `service_role` key — it must never be exposed in frontend code.

## Step 2: Enable GitHub Pages

1. Go to your GitHub repo → **Settings** → **Pages**
2. Under **Source**, select **GitHub Actions** → **Save**

## Step 3: Deploy

Push to `main` branch or manually trigger the workflow:

```
git add .
git commit -m "Deploy OmicVerse"
git push origin main
```

The workflow will:
1. ✅ Run `flutter analyze`
2. ✅ Run `flutter test`
3. ✅ Build Flutter web with Supabase secrets injected
4. ✅ Deploy to GitHub Pages

## Step 4: Supabase Edge Function (Optional)

If using the API proxy for rate-limited external APIs:

```bash
npm install -g supabase
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase secrets set NCBI_API_KEY=your_ncbi_key_here
supabase secrets set ALLOWED_ORIGINS=http://localhost:8080,https://YOUR_USERNAME.github.io
supabase functions deploy api-proxy
```

## Verification Checklist

- [ ] Login works on deployed URL
- [ ] Demo mode works on deployed URL  
- [ ] API proxy tested — unknown domain returns 403
- [ ] Browser DevTools → no secrets visible in network tab or source

## Local Development

```bash
cd app
flutter pub get
flutter run -d chrome
```

Demo mode is always available — no Supabase configuration required.
