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
const MAX_SNIPPETS = 10;

function createSnippets(container) {
  const fragment = document.createDocumentFragment();

  for (let i = 0; i < MAX_SNIPPETS; i++) {
    const el = document.createElement("div");
    const duration = 8 + Math.random() * 12;
    const color = COLORS[Math.floor(Math.random() * COLORS.length)];

    el.className = "codeSnippet";
    el.textContent = CODE_SNIPPETS[Math.floor(Math.random() * CODE_SNIPPETS.length)];
    el.style.cssText = `
      left: ${5 + Math.random() * 90}%;
      font-size: ${0.7 + Math.random() * 0.5}rem;
      --snippet-start: ${100 + Math.random() * 20}cqh;
      --snippet-opacity: ${0.15 + Math.random() * 0.35};
      --snippet-color: var(${color});
      --snippet-duration: ${duration}s;
      --snippet-delay: ${-(i / MAX_SNIPPETS) * duration}s;
    `;
    fragment.appendChild(el);
  }

  container.appendChild(fragment);
}

export const FooterWaves = {
  mounted() {
    this.visible = false;
    this.motionQuery = window.matchMedia("(prefers-reduced-motion: reduce)");

    this.updateAnimation = () => {
      const running = this.visible && !document.hidden && !this.motionQuery.matches;

      if (running && this.el.childElementCount === 0) createSnippets(this.el);
      this.el.toggleAttribute("data-animated", running);
    };

    this.observer = new IntersectionObserver(([entry]) => {
      this.visible = entry.isIntersecting;
      this.updateAnimation();
    });
    this.observer.observe(this.el);
    document.addEventListener("visibilitychange", this.updateAnimation);
    this.motionQuery.addEventListener("change", this.updateAnimation);
  },

  destroyed() {
    this.observer.disconnect();
    document.removeEventListener("visibilitychange", this.updateAnimation);
    this.motionQuery.removeEventListener("change", this.updateAnimation);
    this.el.removeAttribute("data-animated");
    this.el.replaceChildren();
  },
};
