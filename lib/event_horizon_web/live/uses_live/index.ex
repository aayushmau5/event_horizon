defmodule EventHorizonWeb.UsesLive.Index do
  use EventHorizonWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_path={@current_path}>
      <div class="animate-fadeIn">
        <h1 class="font-[Handwriting] text-4xl font-bold mb-4">Uses</h1>
        <p class="mb-4">
          Inspired by{" "}
          <.external_link href="https://usesthis.com/">usesthis.com</.external_link>
        </p>

        <div class="w-full h-auto my-4 mx-auto">
          <img src="/images/desk.webp" alt="My Desk" class="max-w-full rounded-lg" />
        </div>

        <div class="px-4 break-normal">
          <h3 class="text-xl font-bold mt-6 mb-3">Editor</h3>
          <ul class="list-disc pl-6 mb-4 marker:text-(--li-marker)">
            <li>
              VSCode with Vim extension and some{" "}
              <.external_link href="https://github.com/aayushmau5/dotfiles/">
                configuration
              </.external_link>.
            </li>
            <li>
              And sometimes, NeoVim with{" "}
              <.external_link href="https://github.com/aayushmau5/dotfiles/">
                minimal configuration
              </.external_link>.
            </li>
            <li>
              Font: I alternate between{" "}
              <.external_link href="https://github.com/tonsky/FiraCode">Fira Code</.external_link>,{" "}
              <.external_link href="https://commitmono.com/">Commit Mono</.external_link>,{" "}
              <.external_link href="https://github.com/zed-industries/zed-fonts">Zed Mono</.external_link>,{" "}
              <.external_link href="https://juliamono.netlify.app/">Julia Mono</.external_link>{" "} and{" "}
              <.external_link href="https://fonts.adobe.com/fonts/calling-code">Calling Code</.external_link>.
            </li>
            <li>
              Theme:{" "}
              <.external_link href="https://github.com/antfu/vscode-theme-vitesse">Vitesse Dark</.external_link>,{" "}
              <.external_link href="https://www.nordtheme.com/ports/visual-studio-code">Nord</.external_link>{" "} and{" "}
              <.external_link href="https://marketplace.visualstudio.com/items?itemName=GitHub.github-vscode-theme">Github Dark</.external_link>.
            </li>
            <li>
              Icons:{" "}
              <.external_link href="https://marketplace.visualstudio.com/items?itemName=cdonohue.quill-icons">Quill Icons</.external_link>{" "} and{" "}
              <.external_link href="https://marketplace.visualstudio.com/items?itemName=file-icons.file-icons">File Icons</.external_link>.
            </li>
          </ul>

          <h3 class="text-xl font-bold mt-6 mb-3">Terminal</h3>
          <ul class="list-disc pl-6 mb-4 marker:text-(--li-marker)">
            <li>
              <.external_link href="https://sw.kovidgoyal.net/kitty/">Kitty</.external_link>{" "} terminal emulator and{" "}
              <.external_link href="https://fishshell.com/">fish shell</.external_link>
              (with vim mode).
            </li>
            <li>
              Font:{" "}
              <.external_link href="https://www.nerdfonts.com/">FuraCode Nerd Font</.external_link>.
            </li>
            <li>
              Tools:{" "}
              <.external_link href="https://github.com/ogham/exa">Exa</.external_link>,{" "}
              <.external_link href="https://github.com/sharkdp/bat">Bat</.external_link>,{" "}
              <.external_link href="https://github.com/jethrokuan/z">z</.external_link>{" "} and{" "}
              <.external_link href="https://asdf-vm.com/">asdf version manager</.external_link>.
            </li>
          </ul>

          <h3 class="text-xl font-bold mt-6 mb-3">Apps</h3>
          <ul class="list-disc pl-6 mb-4 marker:text-(--li-marker)">
            <li>
              OS:{" "}
              <.external_link href="https://pop.system76.com/">PopOS!</.external_link>{" "} with Gnome DE.
            </li>
            <li>
              Window/Application management: I don't use pop-shell tiling
              mode(that comes pre-configured with PopOS). I organise
              applications in workspaces instead.
            </li>
            <li>Launcher: default pop-shell works well enough for me.</li>
            <li>
              Browser: Firefox as primary web browser, with brave and chromium
              for testing purpose.
            </li>
            <li>
              Note taking:{" "}
              <.external_link href="https://www.notion.so/">Notion</.external_link>{" "} and{" "}
              <.external_link href="https://obsidian.md/">Obsidian</.external_link> (for local stuff).
            </li>
            <li>
              Todos and task management:{" "}
              <.external_link href="https://www.notion.so/">Notion</.external_link>.
            </li>
          </ul>

          <h3 class="text-xl font-bold mt-6 mb-3">Hardware(pretty budget-ish)</h3>
          <ul class="list-disc pl-6 mb-4 marker:text-(--li-marker)">
            <li>Laptop: Apple M2 Air.</li>
            <li>
              Laptop(Old but still works): Dell Inspiron 3576(+ AMD iGPU). Works
              pretty well with linux.
            </li>
            <li>
              Keyboard:{" "}
              <.external_link href="https://keychron.in/product/keychron-k2-v-2/">Keychron K2-V2</.external_link>.
            </li>
            <li>Headphones: Lenovo Ideapad Gaming Headset.</li>
            <li>
              Monitor:{" "}
              <.external_link href="https://www.acer.com/us-en/monitors/gaming/nitro-vg0/pdp/UM.QV0AA.S03">Acer Nitro VG240YS</.external_link>.
            </li>
          </ul>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
