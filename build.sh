#!/bin/bash
# Construit docs/ (application installable Android) à partir de perinee-gasquet.html
set -e
cd "$(dirname "$0")"
V=$(date +%Y%m%d%H%M)
{
  printf '<!doctype html>\n<html lang="fr"><head><meta charset="utf-8">\n<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">\n<link rel="manifest" href="manifest.webmanifest">\n<link rel="icon" href="icon-192.png">\n<link rel="apple-touch-icon" href="icon-192.png">\n<style>:root{color-scheme:light;padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}body{margin:0;font-size:14px}img{max-width:100%%}[hidden]{display:none!important}</style>\n</head><body>\n'
  cat perinee-gasquet.html
  printf '\n</body></html>\n'
} > docs/index.html
cat > docs/manifest.webmanifest <<M
{"name":"Skulpt","short_name":"Skulpt","description":"Périnée, renforcement et cardio doux, méthode de Gasquet","lang":"fr","start_url":"./","scope":"./","display":"standalone","orientation":"portrait","background_color":"#F6F1F4","theme_color":"#D23C72",
"icons":[{"src":"icon-192.png","sizes":"192x192","type":"image/png","purpose":"any maskable"},{"src":"icon-512.png","sizes":"512x512","type":"image/png","purpose":"any maskable"}]}
M
cat > docs/sw.js <<W
const C="skulpt-$V";
const SHELL=["./","index.html","manifest.webmanifest","icon-192.png","icon-512.png"];
self.addEventListener("install",e=>{e.waitUntil(caches.open(C).then(c=>c.addAll(SHELL)));self.skipWaiting()});
self.addEventListener("activate",e=>{e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==C).map(k=>caches.delete(k)))));self.clients.claim()});
self.addEventListener("fetch",e=>{
  const u=new URL(e.request.url);
  if(e.request.method!=="GET")return;
  if(u.origin===location.origin){e.respondWith(fetch(e.request).then(r=>{const cp=r.clone();caches.open(C).then(c=>c.put(e.request,cp));return r}).catch(()=>caches.match(e.request).then(r=>r||caches.match("index.html"))));return}
  if(u.host.includes("fonts.g")){e.respondWith(caches.match(e.request).then(r=>r||fetch(e.request).then(res=>{const cp=res.clone();caches.open(C).then(c=>c.put(e.request,cp));return res})))}
});
W
echo "docs/ construit ($V)"
# icônes (Chrome sans interface)
T=$(mktemp -d)
printf '<html><body style="margin:0">%s</body></html>' "$(sed 's/viewBox="0 0 512 512">/viewBox="0 0 512 512" width="512" height="512" style="display:block">/' icon.svg)" > "$T/icon.html"
perl -e 'alarm 60; exec @ARGV' "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --no-first-run --user-data-dir="$T/p" --hide-scrollbars --window-size=512,512 --screenshot=docs/icon-512.png "file://$T/icon.html" >/dev/null 2>&1
sips -z 192 192 docs/icon-512.png --out docs/icon-192.png >/dev/null
rm -rf "$T"
