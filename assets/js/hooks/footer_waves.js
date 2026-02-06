const CODE_SNIPPETS = [
  // Elixir & Phoenix (from your blogs)
  "defmodule",
  "|>",
  "def",
  "do",
  "end",
  "fn ->",
  "&1",
  ":ok",
  ":error",
  "GenServer",
  "spawn",
  "receive",
  "send",
  "self()",
  "@spec",
  "mix",
  "Phoenix.PubSub",
  "LiveView",
  "mount/3",
  "handle_event/3",
  '~H"""',
  "Enum.reduce",
  "Enum.map",
  "Enum.filter",
  "Task.async",
  "Agent",
  "%Chromosome{}",
  "crossover",
  "mutation",
  "evolve",
  "fitness_function",
  "Path.wildcard",
  "Jason.encode!",
  "Mix.install",
  "nimble_publisher",
  "push_navigate",
  "stream/3",
  "to_form/2",
  "phx-click",
  "phx-hook",

  // Scheme & Racket (from your learning posts)
  "(define",
  "(lambda",
  "(let",
  "(cond",
  "(car",
  "(cdr",
  "(cons",
  "#lang racket",
  "define-syntax",
  "quasiquote",
  "'()",
  "SICP",
  "fn -> :hello_world end",

  // Terminal commands (from distro-hop post)
  "$ git push",
  "$ mix deps.get",
  "$ iex -S mix",
  "$ vim .",
  "$ nvim",
  "$ docker run",
  "$ fish",
  "$ exa",
  "$ starship",
  "$ nvm use",
  "$ mix test",
  "$ mix phx.server",
  "$ fly deploy",

  // VSCode/Vim (from your tips post)
  ":w",
  ":q",
  "<leader>",
  "jk",
  ":tabnew",
  ":tabo",
  "CTRL+T",
  "settings.json",
  "keybindings.json",
  "fontLigatures",

  // Compilers & AST (from visitor pattern post)
  "AST",
  "parse",
  "tokenize",
  "visit()",
  "accept()",
  "traverse",
  "Crafting Interpreters",
  "lexer",
  "parser",
  "eval",

  // Symbols & operators
  "λ",
  ">>",
  "=>",
  "::",
  "->",
  "<-",
  "++",
  "--",
  "&&",
  "||",
  "|>",

  // Containers/infra
  "FROM elixir:1.19",
  "EXPOSE 4000",
  "docker-compose",
  "fly.toml",
  "kubectl apply",
  "nginx.conf",
  "Dockerfile",

  // GSoC & Open Source (from your posts)
  "AsyncAPI",
  "@asyncapi/diff",
  "npm publish",
  "open-source",
  "breaking_change",
  "non_breaking",
  "fast-json-patch",

  // Hex/binary/unicode
  "0x7F",
  "0b1010",
  "0xMEOW",
  "\\u{1F44B}",
  "UTF-8",

  // TypeScript/JS (from your posts)
  "interface",
  "implements",
  "abstract class",
  "extends",
  "async/await",
  "Promise",
  "export default",

  // Fun & personal
  "// TODO:",
  "# FIXME",
  "/* hack */",
  "¯\\_(ツ)_/¯",
  "He is the one",
  "exit 0",
  "BEAM",
  ":erlang",
  "OTP",
  "supervision tree",
  "how do you do?",
  "my name is jeff",
  "meow meow meow",
  "We are in the matrix",
  "Just have fun",
  "Listen to Animals by Pink Floyd",
  "megatron",
  "meowli",
];

const COLORS = ["--theme-one", "--theme-two", "--theme-three", "--theme-four"];
const MAX_SNIPPETS = 25;
const SPAWN_INTERVAL = 400;

function getGlobalState() {
  if (!window.__footerWaves) {
    window.__footerWaves = {
      snippets: [],
      interval: null,
      paused: false,
      visibilityHandler: null,
      container: null,
    };
  }
  return window.__footerWaves;
}

function createSnippet(state) {
  if (!state.container) return;

  const text = CODE_SNIPPETS[Math.floor(Math.random() * CODE_SNIPPETS.length)];
  const el = document.createElement("div");
  el.className = "codeSnippet";
  el.textContent = text;

  const x = 5 + Math.random() * 90;
  const startY = 100 + Math.random() * 20;
  const duration = 8 + Math.random() * 12;
  const delay = Math.random() * 2;
  const size = 0.7 + Math.random() * 0.5;
  const opacity = 0.15 + Math.random() * 0.35;
  const color = COLORS[Math.floor(Math.random() * COLORS.length)];

  el.style.cssText = `
    left: ${x}%;
    top: ${startY}%;
    font-size: ${size}rem;
    --snippet-opacity: ${opacity};
    --snippet-color: var(${color});
    animation: floatUp ${duration}s linear ${delay}s forwards;
  `;

  state.container.appendChild(el);

  const snippet = { el, timeout: null };
  state.snippets.push(snippet);

  snippet.timeout = setTimeout(
    () => {
      el.remove();
      state.snippets = state.snippets.filter((s) => s !== snippet);
    },
    (duration + delay) * 1000 + 100,
  );
}

function startSpawning(state) {
  if (state.interval) return;
  state.interval = setInterval(() => {
    if (!state.paused && state.snippets.length < MAX_SNIPPETS) {
      createSnippet(state);
    }
  }, SPAWN_INTERVAL);
}

function stopSpawning(state) {
  if (state.interval) {
    clearInterval(state.interval);
    state.interval = null;
  }
}

export const FooterWaves = {
  mounted() {
    const state = getGlobalState();
    const wasActive = state.container !== null;

    state.snippets.forEach((s) => {
      clearTimeout(s.timeout);
      s.el.remove();
    });
    state.snippets = [];

    state.container = this.el;

    if (!state.visibilityHandler) {
      state.visibilityHandler = () => {
        if (document.hidden) {
          state.paused = true;
          stopSpawning(state);
        } else {
          state.paused = false;
          startSpawning(state);
        }
      };
      document.addEventListener("visibilitychange", state.visibilityHandler);
    }

    const batchSize = wasActive ? 12 : 8;
    const stagger = wasActive ? 50 : 200;
    for (let i = 0; i < batchSize; i++) {
      setTimeout(() => {
        if (!state.paused) createSnippet(state);
      }, i * stagger);
    }

    startSpawning(state);
  },

  destroyed() {
    const state = getGlobalState();
    stopSpawning(state);
  },
};
