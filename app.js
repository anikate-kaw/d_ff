const chat = document.querySelector("#chat");
const composer = document.querySelector("#composer");
const messageInput = document.querySelector("#message");
const resetButton = document.querySelector("#reset");
const chips = document.querySelectorAll(".chip");

const bootMessage = {
  role: "bot",
  text: "Hey! I\'m Clawdbot Mini. I run entirely in your browser, so you can use me on your phone without any servers.",
};

const botScripts = [
  {
    match: /what can you do|features|capabilities/i,
    respond:
      "I can answer simple questions, suggest plans, and show how to customize a lightweight chatbot. Edit `app.js` to teach me new replies.",
  },
  {
    match: /install|add to home screen|pwa/i,
    respond:
      "Open this page in your mobile browser, then choose \"Add to Home Screen\" to install. It works offline after the first load.",
  },
  {
    match: /study plan|learn|practice/i,
    respond:
      "Try a 3-step plan: 1) pick a topic, 2) schedule 20 minutes daily, 3) track wins in a notes app. Want a plan for a specific subject?",
  },
  {
    match: /hello|hi|hey/i,
    respond: "Hi there! Ask me about customization, or tap a quick prompt below.",
  },
];

const fallbackReplies = [
  "I\'m still learning. Try asking about features, installing me, or creating a study plan.",
  "Not sure yet—teach me by editing the response rules in `app.js`.",
  "Let\'s try something else. Ask me how to customize Clawdbot Mini!",
];

const state = {
  messages: [bootMessage],
};

function renderMessage({ role, text }) {
  const bubble = document.createElement("div");
  bubble.className = `message ${role}`;
  bubble.textContent = text;

  const timestamp = document.createElement("small");
  timestamp.textContent = new Date().toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
  });
  bubble.appendChild(timestamp);

  chat.appendChild(bubble);
  chat.scrollTop = chat.scrollHeight;
}

function renderAll() {
  chat.innerHTML = "";
  state.messages.forEach(renderMessage);
}

function getBotReply(input) {
  const script = botScripts.find((rule) => rule.match.test(input));
  if (script) {
    return script.respond;
  }
  const index = Math.floor(Math.random() * fallbackReplies.length);
  return fallbackReplies[index];
}

function addMessage(role, text) {
  const message = { role, text };
  state.messages.push(message);
  renderMessage(message);
}

function handleSubmit(text) {
  addMessage("user", text);
  const reply = getBotReply(text);
  window.setTimeout(() => addMessage("bot", reply), 450);
}

composer.addEventListener("submit", (event) => {
  event.preventDefault();
  const text = messageInput.value.trim();
  if (!text) return;
  handleSubmit(text);
  messageInput.value = "";
  messageInput.focus();
});

chips.forEach((chip) => {
  chip.addEventListener("click", () => {
    const prompt = chip.dataset.prompt;
    if (prompt) {
      handleSubmit(prompt);
    }
  });
});

resetButton.addEventListener("click", () => {
  state.messages = [bootMessage];
  renderAll();
});

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("service-worker.js");
  });
}

renderAll();
