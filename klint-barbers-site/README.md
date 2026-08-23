# Klint Barbers — Website

Production-ready one-page site for Klint Barbers (Utrecht). Single `index.html`,
no build step, no runtime dependencies — deployable on any static host.

## Files

| File | Purpose |
|---|---|
| `index.html` | The complete site (markup, styles, scripts) |
| `robots.txt` | Crawler policy + sitemap pointer |
| `sitemap.xml` | Single-URL sitemap for search engines |
| `demos/` | Demo folder — see below |

## Demos (`demos/`)

| Demo | Language | Notes |
|---|---|---|
| `demos/nl/index.html` | Dutch | Copy of the production site above |
| `demos/fr/index.html` | French + English | FR by default, **FR ⇄ EN toggle top right** |
| `demos/index.html` | — | Small chooser page linking both demos |

The French demo translates everything live when toggled — page copy, menus,
meta title/description, aria-labels, the booking widget (services, day strip,
summary) and the WhatsApp confirmation message. The choice is remembered
(localStorage) and the visitor's current booking selection survives the
switch. To add or change strings, edit the `I18N` dictionary at the top of
the inline script in `demos/fr/index.html`.

## Online booking (Cal.com)

The site books through [Cal.com](https://cal.com) — open-source scheduling
with a free plan, real availability, calendar sync, automatic reminders and a
Dutch-language booking flow. **Cal.com is enabled by default** with the demo
username `klintbarbers`; connect your own account before launch.

### Connect your own account in 5 steps

1. **Create an account** at <https://cal.com/signup> and pick a username,
   e.g. `klintbarbers` → your booking page is `cal.com/klintbarbers`.
2. **Create one event type per service** with these exact URL slugs
   (Event Types → New):

   | Service | Slug | Duration |
   |---|---|---|
   | Knippen | `knippen` | 30 min |
   | Baard Trimmen | `baard-trimmen` | 20 min |
   | Fade | `fade` | 30 min |
   | Compleet Pakket | `compleet-pakket` | 60 min |

   Prefer different slugs? Fine — update the `events` map in `CAL_CONFIG`
   inside `index.html` to match.
3. **Set availability** (Availability → Working Hours) to the shop hours:
   Mon–Fri 11:00–20:00, Sat 10:00–21:00, Sun 13:00–20:00. Add a minimum
   booking notice (e.g. 1 hour) under each event type's *Limits* tab.
4. **Connect your calendar** (Apps → Google Calendar / Outlook) so booked
   slots are blocked automatically and double bookings are impossible. Under
   *Workflows* you can add automatic e-mail reminders for customers (SMS/
   WhatsApp reminders require a paid Cal.com team plan).
5. **Point the site at your account**: in `index.html`, find `CAL_CONFIG`
   and set `username` to yours. Done.

### How the booking flow behaves

- The submit button reads **"Bevestig Afspraak"** (calendar icon) and opens
  the Cal.com overlay in the page, pre-filled with the chosen service and day —
  showing *real* availability, in the site's dark/gold theme.
- **The site's own day/time picker is live too**: when a visitor picks a
  service, the page fetches the real free slots from Cal.com's public API for
  the whole booking horizon. Times that are already booked disappear from the
  grid (and come back when a booking is cancelled); fully-booked days show as
  dimmed, unclickable tiles. The data refreshes every minute and when the
  visitor returns to the tab. If the request fails for any reason — account
  not set up yet, API unreachable — the widget silently falls back to the
  plain opening-hours grid, and the Cal.com overlay remains the gatekeeper
  that makes double bookings impossible either way.
- If the Cal.com embed script is blocked or fails to load, the button's
  plain link goes to the same Cal.com booking page, so booking still works.
- The Cal.com embed script is loaded lazily, only when the visitor scrolls
  near the booking section — it never slows down page load.
- **WhatsApp flow (optional fallback)**: setting `CAL_CONFIG.enabled: false`
  switches the widget to a WhatsApp flow — the button opens a chat with the
  visitor's booking details pre-filled. That requires a number in
  `BOOKING_CONFIG.whatsapp`; with Cal.com disabled *and* no number, the
  button stays safely disabled.

Bookings arrive in your Cal.com dashboard, your connected calendar, and by
e-mail.

## Instagram gallery

In `index.html`, find `INSTAGRAM_CONFIG`:

1. Replace `handle` with the shop's Instagram username.
2. Replace each placeholder in `posts` with a real post shortcode — for a post
   at `instagram.com/p/CzABoLnoTtX/`, the shortcode is `CzABoLnoTtX`.
3. Set `configured: true` — this hides the beige template banner.

Embeds load lazily as visitors scroll, so the six iframes never compete with
page load.

## Editing content

- **Opening hours** live in three places — keep them in sync:
  the footer ("Openingstijden"), `BOOKING_CONFIG.hours` (JS weekday numbers:
  0 = Sunday), and `openingHoursSpecification` in the JSON-LD block in `<head>`.
- **Services & prices**: the service cards in the *Diensten* section (HTML) and
  `BOOKING_CONFIG.services` (JS). When Cal.com is enabled, also update the
  event types there.
- **Phone / WhatsApp number**: the site ships **without** a phone number
  (demo). To add one: put it in `BOOKING_CONFIG.whatsapp` (digits only, incl.
  country code, e.g. `31612345678`) — that single setting turns the floating
  WhatsApp button into a real `wa.me` link (and powers the widget's WhatsApp
  fallback when Cal.com is disabled). While it's empty, the floating button
  safely scrolls to the booking section instead. If you also want a visible/
  dialable number, add a `tel:` link back in the header, the mobile menu, the
  footer *Contact* list, and a `"telephone"` property in the JSON-LD block
  in `<head>`.
- **Address**: *Klintstraat 12, Utrecht* is a **fictional demo address**.
  Replace it with the real one in three spots: the footer *Contact* list,
  the photo caption in the *Over Ons* section, and `streetAddress` in the
  JSON-LD block. While you're at it, add the postcode to the JSON-LD
  `address` (`"postalCode": "…"`) — it strengthens the match with your
  Google Business Profile.

## Before launch — owner decisions

Things that were deliberately **not** changed because they alter the visible
design or need information only you have:

- **Facebook link**: the footer icon points at `facebook.com` (a placeholder).
  Point it at the real page — and add that URL to `sameAs` in the JSON-LD —
  or remove the icon.
- **Photos**: the hero/section images and the social-share image
  (`og:image`) are Unsplash stock served from Unsplash's CDN. For launch,
  self-host real shop photos (social image: 1200×630) so previews never
  break and the imagery is genuinely yours.
- **Text contrast (WCAG AA)**: three inherited color pairs fail the 4.5:1
  contrast minimum: the grey `#6e6e6e` body copy on the cream sections
  (≈3.9:1), the gold "— Over Ons —"-style labels on cream (≈1.7:1), and the
  footer copyright line (≈3.4:1). Fixing them changes the look (e.g. darken
  the grey to `#595959`), so it's your call — everything else on the page
  passes.
- **Privacy (GDPR/ePrivacy)**: Google Fonts and — once configured — the
  Instagram embeds load from third-party servers without a consent banner,
  which EU regulators have objected to. The robust fixes are self-hosting
  the three font families and making the Instagram tiles click-to-load.

## Performance & robustness (what was done)

- **No runtime CSS compiler**: the Tailwind CDN script (a ~100 KB+ blocking
  JavaScript compiler, explicitly not for production) was replaced with a
  precompiled, minified 14 KB stylesheet inlined into the page — zero visual
  change, verified by automated pixel-comparison at desktop and mobile widths.
- **LCP preload**: the hero image is preloaded at top priority;
  preconnect/dns-prefetch for the image and embed origins.
- **Lazy Instagram embeds**: iframes are created only when tiles approach the
  viewport (with reserved height, so the layout never shifts).
- **SEO**: canonical URL, Open Graph/Twitter cards, SVG favicon, JSON-LD with
  complete & consistent opening hours (incl. Sunday), `robots.txt`, `sitemap.xml`.
- **Accessibility**: skip-to-content link, `aria-pressed` states and real
  button semantics in the booking widget, live-region booking summary, Escape
  closes the mobile menu, `prefers-reduced-motion` respected.
- **Bug fixes**: local-timezone date keys (UTC `toISOString` shifted dates
  around midnight), booking hours now match the published opening hours, the
  disabled submit link can no longer be keyboard-activated, footer year updates
  itself, footer Instagram icon links to the configured profile.

## Deploying

Upload the three files to any static host — Netlify, Vercel, Cloudflare Pages,
GitHub Pages, or classic hosting. If the domain is not `klintbarbers.nl`,
update the URLs in: canonical/OG tags, JSON-LD, `robots.txt`, `sitemap.xml`.
Update `<lastmod>` in `sitemap.xml` when you deploy content changes.

If your host lets you set response headers, a Content-Security-Policy header
is a worthwhile hardening step for the Cal.com go-live (the embed script runs
with full page access). A working policy for this site:

```
default-src 'self'; script-src 'self' 'unsafe-inline' https://app.cal.com;
style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
font-src https://fonts.gstatic.com; img-src 'self' data: https://images.unsplash.com;
frame-src https://www.instagram.com https://app.cal.com;
connect-src https://app.cal.com https://api.cal.com
```
