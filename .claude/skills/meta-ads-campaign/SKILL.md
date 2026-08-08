---
name: meta-ads-campaign
description: End-to-end playbook for creating a Meta (Instagram/Facebook) ads campaign via the meta-ads MCP — discovery, audience seeding, ToS gates, image hosting, IG linkage, conversion-event optimization, and the gotchas that block first-time launches. TRIGGER when the user asks to launch a Meta/Facebook/Instagram ad campaign, build a Lookalike audience for Meta, set up Meta conversion optimization, or troubleshoot Meta Ads Manager errors during campaign creation. SKIP when working on Google Ads, LinkedIn Ads, TikTok Ads, or just analyzing existing Meta campaign performance.
---

# Create Meta Ads Campaign

End-to-end recipe for launching a Meta conversion campaign via the meta-ads MCP. Built from a real launch where every "obvious" step had a non-obvious gotcha. Read the full sequence — skipping ahead means you'll hit blockers without context.

## Prerequisites — gather before starting

| Field | How to find | Notes |
|---|---|---|
| **Ad account ID** | `ads_get_ad_accounts` | Filter for `is_ads_mcp_enabled: true`. Watch for `currency` mismatch with user's stated budget (USD vs PLN etc.). |
| **Business ID** | Same call, `business_id` field | Different from ad account ID. |
| **Page ID** | `ads_get_user_pages` or `ads_get_ad_account_pages` | Required for every creative. |
| **IG user ID** | See "Instagram linkage" below — the user's first guess is almost always wrong. |
| **Pixel/Dataset ID** | `ads_get_datasets` for the business | Usually already exists if PostHog→Meta CAPI is wired. |
| **Custom event names** | Check existing PostHog→Meta destination's event filter, or `ads_get_dataset_quality` (lists events received) | These are the `custom_event_str` values for optimization. |

## Step 0 — Verify CAPI/Pixel health

Before any campaign, confirm events are flowing:

```
ads_get_dataset_quality(dataset_id=<PIXEL_ID>)
ads_get_dataset_stats(dataset_id=<PIXEL_ID>, aggregation="event")
```

Look for:
- The intended conversion event present with ≥250 events/week (or similar volume floor for the 50/wk learning-phase rule)
- Email match coverage ≥80% (lower means weak CAPI matching — fix the PostHog identify path before launching)
- A clean event whitelist on the PostHog→Meta destination — if `$autocapture`, `$pageview`, every PostHog system event is being forwarded, you'll dilute Meta's signal. Filter to 3-5 conversion events max.

## Step 1 — Build the audience (in this order, not the other way)

### 1a. Customer-list audience (DFCA, subtype=CUSTOM)

Use as the **exclusion** for prospecting, NOT the LAL seed (too small for per-country thresholds at early-stage scale).

**ToS gate (one-time per ad account)**: the create call fails with error #200/1870090 the first time. URL is in the error message:
`https://business.facebook.com/ads/manage/customaudiences/tos/?act=<AD_ACCOUNT_ID>`

User must click Accept manually.

The MCP auto-hashes emails — pass raw emails in `data`, schema `["EMAIL"]`. **Note: bulk PII uploads via MCP may be blocked by host classifiers as data exfiltration; if blocked, the user must CSV-upload through Ads Manager UI.**

### 1b. Website Custom Audience (WCA, subtype=WEBSITE) — the real LAL seed

**Why**: per-country LAL needs ≥100 matched users in the target country. Customer-list seeds usually have <100 per country for early-stage SaaS. WCAs built from Pixel events have 5-10× the volume.

**ToS gate (separate from customer-list ToS!)**: error #2663 the first time, URL:
`https://www.facebook.com/customaudiences/app/tos/?act=<AD_ACCOUNT_ID>`

Rule structure (`rule` must be a JSON-encoded STRING, not a nested object):

```json
{
  "inclusions": {
    "operator": "or",
    "rules": [{
      "event_sources": [{"type": "pixel", "id": "<PIXEL_ID>"}],
      "retention_seconds": 15552000,
      "template": "VISITORS_BY_URL",
      "filter": {
        "operator": "and",
        "filters": [
          {"field": "event", "operator": "eq", "value": "<event_name>"}
        ]
      }
    }]
  }
}
```

`retention_seconds: 15552000` = 180 days. Use the highest-intent custom event you have (e.g. `base_image_upload_started`, not `$pageview`).

### 1c. Lookalike (LAL, subtype=LOOKALIKE)

**Per-country minimum: 100 matched users.** If single-country fails with error #2654, options:

1. Use a WCA seed (more users → satisfies threshold)
2. Build LAL via Meta UI (sometimes a country picker exists where API rejects)
3. Use multi-country LAL (cover EEA / Anglosphere / your strongest 6-8 countries)
4. **DO NOT** assume "Worldwide" works — in current UI it's only available as a region-pick option and not always present. Web search results that claim worldwide LAL "always works" are stale.

`lookalike_ratio: 0.01` = 1% (tightest match). `0.05` = 5% (broader, lower quality).

## Step 2 — Get the Instagram user ID

The user's first answer is almost always wrong. Reliable sequence:

1. **Don't trust** what they paste from Business Settings — they often confuse Business ID, Page ID, and IG user ID, and the UI doesn't always show the right one.
2. **Don't use** the `ads_get_ig_accounts` MCP tool — it's been "gradually rolling out" for years; expect "not yet enabled" responses.
3. **Best path**: grep the public Instagram profile HTML:
   ```bash
   curl -s -A "Mozilla/5.0..." https://www.instagram.com/<handle>/ | \
     grep -oE '17[68][0-9]{14,16}' | sort -u
   ```
   Returns the 17-digit Instagram Business Account (IGBA) ID. **This is the correct format** for `instagram_user_id`/`instagram_actor_id`.
4. If the create_creative call rejects the IG ID with "must be a valid Instagram account id" even though you have the right number, the **IG → ad account asset assignment** is broken at the Business Settings layer. User needs to fix it via Business Settings → Instagram accounts → Add Assets (both Page and Ad Account, both with admin permission). This step often fails with "Try later" — wait 10-30 min and retry.

## Step 3 — Image hosting (subtle disaster)

**Don't trust user-uploaded image hashes from Meta Media Library.** Meta Media Library lives at the **Business Asset level**, not the **ad-account adimages level**. Hashes uploaded there show up in `ads_get_ad_images` listings (because of cross-account visibility), but `ads_create_creative` will accept them while `ads_create_ad` will reject with **error #2446386** ("image not available") at delivery review time. Meta dedupes by file content hash, so re-uploading the same PNG won't escape the bad-scope state.

**Reliable fix**: host the image at a public URL (e.g. commit to `/public/ads/` in the Next.js repo + deploy), then pass `image_url` to `ads_create_creative` instead of `image_hash`. Meta fetches the URL, re-hashes, and stores in the ad account's adimages library properly.

**Verify**: `ads_get_ad_images(hashes=[<hash>])` returns empty when listing without filter shows the image. This means the hash is Business-scoped, not ad-account-owned. Image_url is the fix.

## Step 4 — Campaign / ad set / ad creation

Standard flow:

```
1. ads_create_campaign(objective=OUTCOME_SALES, buying_type=AUCTION, campaign_daily_budget=<cents>)
   → CBO by default. Use `LOWEST_COST_WITHOUT_CAP` bid strategy.
   → Returns valid_optimization_goals for the objective — use one of those, do NOT guess.

2. ads_create_ad_set(
     campaign_id=...,
     billing_event=IMPRESSIONS,
     optimization_goal=OFFSITE_CONVERSIONS,
     destination_type=WEBSITE,
     promoted_object={"pixel_id":"<PIXEL>","custom_event_type":"OTHER","custom_event_str":"<event_name>"},
     targeting=<see below>
   )

3. ads_create_creative(
     page_id=<PAGE>,
     instagram_user_id=<IG_USER_ID>,  ← REQUIRED for IG delivery (omitting means FB-only)
     image_url=https://yourdomain.com/ads/<image>.png,  ← NOT image_hash; see Step 3
     link_url=https://yourdomain.com/?utm_source=meta&utm_medium=ig&utm_campaign=<name>&utm_content=<variant>,
     message=<≤125 char primary text>,
     headline=<short headline>,
     call_to_action_type=LEARN_MORE  ← TRY_NOW doesn't exist in the enum; LEARN_MORE/SIGN_UP/GET_STARTED are the available CTAs for SaaS
   )

4. ads_create_ad(ad_set_id=..., creative={"creative_id":<from step 3>})
```

Everything is created **PAUSED** by default. User flips live in Ads Manager after preview.

### Targeting spec (for B2B IG-only prospecting)

```json
{
  "geo_locations": {
    "countries": ["US"],
    "location_types": ["home", "recent"]   ← CRITICAL, see Step 6
  },
  "age_min": 25,
  "age_max": 65,
  "publisher_platforms": ["instagram"],
  "instagram_positions": ["stream", "story"],
  "device_platforms": ["mobile", "desktop"],
  "custom_audiences": [{"id": "<LAL_ID>"}],
  "excluded_custom_audiences": [{"id": "<CUSTOMER_LIST_ID>"}]
}
```

- `publisher_platforms: ["instagram"]` is the only way to fully exclude FB (don't trust placement panel checkboxes alone)
- `instagram_positions`: `stream` = Feed, `story` = Stories. Add `"reels"` only if you have 9:16 video; otherwise it letterboxes and looks bad.
- Mobile-only is tempting for IG but **leave desktop on** because the conversion (signup, app use) typically happens on desktop. Meta's cross-device attribution handles the journey if email match is good.

## Step 5 — Default to multiple ads in one ad set (3-5 variations)

Same ad set, multiple creatives. Meta's algo rotates and finds the winner. Three variants is the sweet spot. All paused on create.

## Step 6 — Location targeting deprecation (error #1870194)

Meta deprecated the older `travel_in` location type. If you see error **#1870194** ("Your audience contains a location targeting option that has been removed"), the cause is **nested deprecated values** in the targeting object (not the top-level `location_types`).

**Fix that often DOESN'T work**: `ads_update_entity` with `location_types: ["home", "recent"]`. The top-level field updates but nested `regions`/`cities`/`zips` arrays may still carry the deprecated value.

**Fix that DOES work**: user removes the country in Ads Manager UI, then re-adds it. The UI's "remove location" wipes the entire geo_locations object; re-adding rebuilds from current valid defaults.

If you've already API-patched and the error persists, tell the user to do this manual reset.

## Step 7 — Cleanup

No "delete creative" tool exposed. To soft-delete ads (e.g. the broken-image v1 ads while keeping the v2 ones):

```
ads_update_entity(entity_id=<ad_id>, entity_type="ad", fields={"status":"DELETED"})
```

Orphaned creatives (not bound to any ad) just sit there — harmless. Mention this to the user so they don't think you forgot.

## Verification before flip-live

1. **`ads_get_ad_preview`** for one ad on each placement (`INSTAGRAM_STANDARD`, `INSTAGRAM_STORY`) to confirm the visual renders without weird letterboxing
2. **Events Manager** → dataset → Test events → fire a test conversion via PostHog with a `test_event_code` — confirm it arrives within 60s with hashed email + fbc populated
3. **Aggregated Event Measurement**: 8-event priority list assigned for the verified domain. Without this, iOS 14.5+ users won't be measured. Priorities: Subscribe > Activation > Upload (or your equivalents)
4. **Domain verification** for the destination URL — meta tag in `<head>` (managed via Next.js `metadata.other` field) — Meta verifies via crawler
5. **Budget**: confirm currency matches account, and amount converted correctly (PLN→USD, etc.)

## Common errors and their actual meanings

| Error | What it really means | Fix |
|---|---|---|
| #200/1870090 | Custom Audience ToS not accepted | URL in error message, click Accept |
| #2663 | Website Custom Audience ToS not accepted (separate from above) | URL in error message |
| #2654 | LAL source has <100 in target country | Use bigger seed (WCA over DFCA) or multi-country |
| #2446386 | Image is Business-scoped, not ad-account-owned | Use `image_url` instead of `image_hash` |
| #1870194 | Deprecated `travel_in` in nested geo config | Remove + re-add country in UI |
| "must be a valid Instagram account id" | IG-ad-account asset link broken | Business Settings → Instagram → Add Assets → fix linkage |
| MCP error -32603 generic | Often a bad `instagram_user_id` or `{{template}}` URL params | Test minimal-params creative first to isolate |

## Sensible defaults

- **Budget**: $20-50/day for prospecting. Below $20 and the algo doesn't have data to optimize.
- **Bid strategy**: LOWEST_COST_WITHOUT_CAP (autobid) for first 2-4 weeks
- **Attribution**: 7-day click + 1-day view (Meta default)
- **Optimization event**: highest-volume *intent* event (upload/signup/lead), not lowest-funnel money event — Meta's learning phase needs ≥50/wk
- **Switch optimization to value event** (Subscribe/Purchase) only after ≥30/wk of that event lands
- **Don't kill anything before day 7-14**. Learning phase noise dominates early data.

## What this skill does NOT cover

- Catalog/Dynamic Product Ads (out of scope for SaaS subscriptions)
- Reels video creatives (need 9:16 video assets and a separate creative spec)
- Lead Gen forms (separate flow with `OUTCOME_LEADS` + ToS at facebook.com/legal/leadgen/tos)
- Messaging-destination campaigns (Messenger/WhatsApp/IG Direct)
- Reach & Frequency buying type (only AUCTION covered here)
- The PostHog → Meta CAPI destination setup — that's covered by PostHog docs, not this skill
