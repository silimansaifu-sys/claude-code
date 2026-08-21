# Klint Barbers — Website

Production-ready one-page site for Klint Barbers (Utrecht). Single `index.html`,
no build step, no runtime dependencies — deployable on any static host.

## Files

| File | Purpose |
|---|---|
| `index.html` | The complete site (markup, styles, scripts) |
| `robots.txt` | Crawler policy + sitemap pointer |
| `sitemap.xml` | Single-URL sitemap for search engines |

## Online booking (Cal.com)

The booking widget is fully wired for [Cal.com](https://cal.com) — open-source
scheduling with a free plan, real availability, calendar sync, automatic
reminders and a Dutch-language booking flow. **Until you connect an account the
widget falls back to the WhatsApp flow, which works out of the box.**

### Go live in 5 steps

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
   *Workflows* you can add automatic e-mail/SMS reminders for customers.
5. **Flip the switch**: in `index.html`, find `CAL_CONFIG` and set
   `enabled: true` (and `username` if it differs). Done.

### What changes when Cal.com is enabled

- The submit button becomes **"Bevestig Afspraak"** (calendar icon) and opens
  the Cal.com overlay in the page, pre-filled with the chosen service and day —
  showing *real* availability, in the site's dark/gold theme.
- If the embed script is blocked or JavaScript is unavailable, the button's
  plain link goes to the same Cal.com booking page — booking always works.
- The floating WhatsApp button stays, so customers can still reach you directly.
- The Cal.com embed script is loaded lazily, only when the visitor scrolls
  near the booking section — it never slows down page load.

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
- **Phone number**: appears in the header, footer, the two WhatsApp links
  (`BOOKING_CONFIG.whatsapp`, digits only) and JSON-LD.
- ⚠️ **Address check**: the footer and JSON-LD say *Hofnarlaan 2*, but the
  photo caption in the *Over Ons* section says *Voorstraat 88*. Both were left
  as-is (visible content) — correct whichever one is wrong.

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
