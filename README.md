# Stego Platform PWA — Local Working Prototype

Deploy-ready GitHub Pages build.

## What's working now
- PWA install + service worker
- Smooth astronaut/rocket splash animation
- No planet graphic in splash
- Customer food cart
- Local food orders
- Local Stegoland ticket bookings
- Local school-visit requests
- Admin menu edit / add / sold-out controls
- Admin settings
- Member database
- Dashboard KPIs calculated from locally saved activity
- JSON full backup / restore
- CSV member, order and school-visit exports
- LocalStorage persistence across browser refreshes

## Storage
This version uses browser `localStorage`, so it is ideal for prototyping before Firebase.

Data stays on the same browser/device only. Clearing browser site data will remove it unless a JSON backup is exported first.

## GitHub Pages
Upload every file in this folder to the repository root and enable GitHub Pages from `main` / root.

