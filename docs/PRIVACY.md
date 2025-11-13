# Privacy

**Everything is stored locally. Nothing goes online. Dont panic.**

Look, I don't want your data. I don't want to track you. I don't want to sell you anything. I just want my bookmarks in a floating strip. So that's what this does. Your data stays on your Mac. Period. 

_Now what Apple does to your data is none of my business..._

All your data stays on your Mac:
- Bookmarks stored in `~/Library/Application Support/NeoNav/bookmarks.json`
- Preferences stored in `~/Library/Application Support/NeoNav/preferences.json`
- Window position stored in macOS UserDefaults

When you add a bookmark, NeoNav fetches the website's favicon (icon). This involves:
- Making network requests to the website's domain
- Using Google's public favicon service as a fallback
- Caching favicons locally

No personal information is transmitted. No tracking. No analytics. Just favicon fetching.

