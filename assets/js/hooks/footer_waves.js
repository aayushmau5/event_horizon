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
  "fitness",
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
];

export const FooterWaves = {
  mounted() {
    this.snippets = [];
    this.maxSnippets = 25;
    this.paused = false;

    // Pause when tab is hidden to prevent burst on return
    this.handleVisibility = () => {
      if (document.hidden) {
        this.paused = true;
        if (this.interval) {
          clearInterval(this.interval);
          this.interval = null;
        }
      } else {
        this.paused = false;
        this.startSpawning();
      }
    };
    document.addEventListener("visibilitychange", this.handleVisibility);

    // Create initial batch
    for (let i = 0; i < 8; i++) {
      setTimeout(() => {
        if (!this.paused) this.createSnippet();
      }, i * 200);
    }

    this.startSpawning();
  },

  startSpawning() {
    if (this.interval) return;
    this.interval = setInterval(() => {
      if (!this.paused && this.snippets.length < this.maxSnippets) {
        this.createSnippet();
      }
    }, 400);
  },

  destroyed() {
    if (this.interval) clearInterval(this.interval);
    document.removeEventListener("visibilitychange", this.handleVisibility);
    this.snippets.forEach((s) => s.el.remove());
  },

  createSnippet() {
    const text =
      CODE_SNIPPETS[Math.floor(Math.random() * CODE_SNIPPETS.length)];
    const el = document.createElement("div");
    el.className = "codeSnippet";
    el.textContent = text;

    // Random horizontal position
    const x = 5 + Math.random() * 90;
    // Start from bottom
    const startY = 100 + Math.random() * 20;

    // Random properties
    const duration = 8 + Math.random() * 12;
    const delay = Math.random() * 2;
    const size = 0.7 + Math.random() * 0.5;
    const opacity = 0.15 + Math.random() * 0.35;

    // Pick a theme color
    const colors = [
      "--theme-one",
      "--theme-two",
      "--theme-three",
      "--theme-four",
    ];
    const color = colors[Math.floor(Math.random() * colors.length)];

    el.style.cssText = `
      left: ${x}%;
      top: ${startY}%;
      font-size: ${size}rem;
      --snippet-opacity: ${opacity};
      --snippet-color: var(${color});
      animation: floatUp ${duration}s linear ${delay}s forwards;
    `;

    this.el.appendChild(el);

    const snippet = { el, timeout: null };
    this.snippets.push(snippet);

    // Clean up after animation
    snippet.timeout = setTimeout(
      () => {
        el.remove();
        this.snippets = this.snippets.filter((s) => s !== snippet);
      },
      (duration + delay) * 1000 + 100,
    );
  },
};
