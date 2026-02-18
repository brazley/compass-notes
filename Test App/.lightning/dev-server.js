const fs = require("fs");
const path = require("path");

// --- Configuration via environment variables ---
const PORT = parseInt(process.env.LIGHTNING_PORT || "3274", 10);
const ROOT = process.env.LIGHTNING_ROOT || process.cwd();
const ENTRY = process.env.LIGHTNING_ENTRY || "index.html";
const WATCH_EXTENSIONS = (process.env.LIGHTNING_WATCH_EXTENSIONS || "html,css,js,json,ts,tsx,jsx")
    .split(",")
    .map(function(ext) { return ext.trim(); });
const DEBOUNCE_MS = 300;

const IGNORE_DIRS = ["node_modules/", ".lightning/", ".git/", ".build/"];

// --- MIME type mapping ---
const MIME_TYPES = {
    ".html": "text/html; charset=utf-8",
    ".htm": "text/html; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".js": "application/javascript; charset=utf-8",
    ".ts": "application/javascript; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".svg": "image/svg+xml",
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".gif": "image/gif",
    ".ico": "image/x-icon",
    ".woff": "font/woff",
    ".woff2": "font/woff2"
};

// --- Hot reload client script injected into HTML ---
var HOT_RELOAD_CLIENT = "<script>(function(){" +
    "var retryDelay=1000;" +
    "function connect(){" +
        "var ws=new WebSocket('ws://'+location.host+'/ws');" +
        "ws.onopen=function(){retryDelay=1000;};" +
        "ws.onmessage=function(e){" +
            "var data=JSON.parse(e.data);" +
            "if(data.type==='css-reload'){" +
                "document.querySelectorAll('link[rel=\"stylesheet\"]').forEach(function(link){" +
                    "var url=new URL(link.href);" +
                    "url.searchParams.set('_hmr',Date.now());" +
                    "link.href=url.href;" +
                "});" +
            "}else{" +
                "location.reload();" +
            "}" +
        "};" +
        "ws.onclose=function(){" +
            "setTimeout(function(){" +
                "retryDelay=Math.min(retryDelay*1.5,5000);" +
                "connect();" +
            "},retryDelay);" +
        "};" +
    "}" +
    "connect();" +
"})();</script>";

// --- Bun HTTP + WebSocket server ---
var server = Bun.serve({
    port: PORT,
    fetch: function(req, server) {
        var url = new URL(req.url);

        // Upgrade WebSocket requests
        if (url.pathname === "/ws" || req.headers.get("upgrade") === "websocket") {
            if (server.upgrade(req)) {
                return undefined;
            }
            return new Response("WebSocket upgrade failed", { status: 400 });
        }

        var filePath = url.pathname === "/" ? ENTRY : url.pathname.slice(1);
        var fullPath = path.join(ROOT, filePath);

        var file = Bun.file(fullPath);
        return file.exists().then(function(exists) {
            if (!exists) {
                return new Response("Not Found", { status: 404 });
            }

            var ext = path.extname(fullPath).toLowerCase();

            // Inject hot reload script into HTML files
            if (ext === ".html" || ext === ".htm") {
                return file.text().then(function(html) {
                    var bodyIndex = html.lastIndexOf("</body>");
                    if (bodyIndex !== -1) {
                        html = html.slice(0, bodyIndex) + HOT_RELOAD_CLIENT + html.slice(bodyIndex);
                    } else {
                        html = html + HOT_RELOAD_CLIENT;
                    }
                    return new Response(html, {
                        headers: { "Content-Type": MIME_TYPES[ext] || "text/html; charset=utf-8" }
                    });
                });
            }

            var contentType = MIME_TYPES[ext];
            if (contentType) {
                return new Response(file, {
                    headers: { "Content-Type": contentType }
                });
            }
            return new Response(file);
        });
    },
    websocket: {
        open: function(ws) {
            ws.subscribe("reload");
        },
        close: function(ws) {
            ws.unsubscribe("reload");
        },
        message: function() {}
    }
});

// --- File watcher with debounce ---
var debounceTimer = null;
var pendingChanges = [];

var watcher = fs.watch(ROOT, { recursive: true }, function(eventType, filename) {
    if (!filename) return;

    // Ignore directories
    for (var i = 0; i < IGNORE_DIRS.length; i++) {
        if (filename.startsWith(IGNORE_DIRS[i]) || filename.indexOf("/" + IGNORE_DIRS[i]) !== -1) return;
    }

    var ext = path.extname(filename).slice(1).toLowerCase();
    if (WATCH_EXTENSIONS.indexOf(ext) === -1) return;

    pendingChanges.push({ file: filename, ext: ext });

    if (debounceTimer) clearTimeout(debounceTimer);
    debounceTimer = setTimeout(function() {
        var changes = pendingChanges.slice();
        pendingChanges = [];

        var allCss = changes.every(function(c) { return c.ext === "css"; });

        if (allCss) {
            console.log("[Lightning] CSS changed -> css-reload");
            server.publish("reload", JSON.stringify({ type: "css-reload" }));
        } else {
            var lastFile = changes[changes.length - 1].file;
            console.log("[Lightning] " + lastFile + " changed -> reload");
            server.publish("reload", JSON.stringify({ type: "reload", file: lastFile }));
        }
    }, DEBOUNCE_MS);
});

// --- Graceful shutdown ---
function shutdown() {
    console.log("[Lightning] Shutting down...");
    watcher.close();
    server.stop();
    process.exit(0);
}

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);

// --- Startup output ---
console.log("[Lightning] Dev server starting...");
console.log("[Lightning]   Port: " + PORT);
console.log("[Lightning]   Root: " + ROOT);
console.log("[Lightning]   Entry: " + ENTRY);
console.log("[Lightning]   Watch: " + WATCH_EXTENSIONS.join(", "));
console.log("LIGHTNING_DEV_READY");