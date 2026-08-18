# Stego Platform PWA

GitHub Pages deploy-ready build.

## Included
- Progressive Web App manifest
- Service worker with offline app-shell caching
- Installable icons (192, 512, maskable)
- Animated Stego splash screen
- Astronaut/logo flying through space toward Stegoland
- Existing customer and admin mockup
- Menu, membership, booking, school visits, backup/export UI

## Deploy to GitHub Pages
1. Create/open a GitHub repository.
2. Upload all files from this folder to the repository root.
3. Go to **Settings → Pages**.
4. Select **Deploy from a branch**.
5. Choose `main` and `/ (root)`.
6. Save and wait for deployment.

### Important for PWA testing
GitHub Pages uses HTTPS, so the service worker and PWA install flow work correctly there.

### Files
- `index.html`
- `manifest.webmanifest`
- `sw.js`
- `icon-192.png`
- `icon-512.png`
- `icon-maskable-512.png`
- `.nojekyll`

- Admin dashboard emojis replaced with professional inline SVG iconography.

- Splash astronaut is now isolated on a transparent background with no square box.
- Astronaut and rocket flame have been enlarged.
- Customer header now uses a transparent Stegoland logo for better visual blending.

- Splash now uses the astronaut riding the red-and-white rocket asset.
- No Stegoland text/background is attached to the flying asset.
- Flying rocket is larger with a smoother, more cinematic trajectory.
- Removed duplicate CSS flame because the artwork already contains rocket flames.
