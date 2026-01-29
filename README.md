# Clawdbot Mini

Clawdbot Mini is a tiny, phone-friendly chatbot you can run locally with no servers. It ships as a static web app with offline support, so you can install it on a phone like any other app.

## Run locally

Use any static web server. For example:

```bash
python3 -m http.server 8080
```

Then open `http://localhost:8080` in your browser.

## Install on a phone

1. Start the local server on your computer.
2. Open the app from your phone on the same Wi-Fi network (use your computer's IP address, e.g. `http://192.168.1.25:8080`).
3. In the browser menu, tap **Add to Home Screen** to install it.
4. After the first load, it works offline.

## Customize responses

Edit `app.js` to add rules:

```js
{
  match: /your regex/i,
  respond: "Your response here"
}
```

You can also tweak the look in `styles.css`.
