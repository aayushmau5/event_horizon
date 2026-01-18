# Command Bar

A keyboard-driven command palette (similar to [kbar](https://kbar.vercel.app/)) for quick navigation and actions.

## Overview

The command bar provides a fast way to navigate the site and perform actions using keyboard shortcuts. It's accessible from any page since it's rendered in the app layout.

## Usage

- **Open**: Press `⌘ + K` (Mac) or `Ctrl + K` (Windows/Linux), or click the `⌘ K` button in the navigation bar
- **Close**: Press `Escape` or click outside the modal
- **Navigate**: Use `↑` / `↓` arrow keys to move through results
- **Execute**: Press `Enter` or click on a result
- **Filter**: Type to filter commands by title or subtitle

## Architecture

```
lib/event_horizon_web/components/
├── command_bar.ex      # Component module
├── layouts.ex          # Imports and renders <.command_bar />
└── page_components.ex  # Nav button imports show_command_bar/1

assets/css/
└── command_bar.css     # Styling
```

## Component Structure

### command_bar.ex

The component consists of three main parts:

#### 1. HEEx Template

```heex
<div id={@id} class="commandBarPositioner" style="display: none;" phx-hook=".CommandBar">
  <div class="commandBarAnimator" data-animator>
    <input ... data-search-input />
    <div class="commandBarResultsContainer">
      <!-- Section headers and command results -->
    </div>
  </div>
</div>
<script :type={Phoenix.LiveView.ColocatedHook} name=".CommandBar">
  // JavaScript hook
</script>
```

Key elements:
- **Positioner**: The backdrop/overlay that covers the screen
- **Animator**: The modal container with the actual content
- **Search input**: For filtering commands
- **Results container**: Lists all available commands grouped by section

#### 2. Colocated JavaScript Hook

The `.CommandBar` hook handles all interactivity:

```javascript
export default {
  mounted() {
    // Initialize references to DOM elements
    // Set up event listeners for:
    //   - Input filtering
    //   - Keyboard navigation (arrows, enter)
    //   - Click outside to close
    //   - Click on results to execute
    //   - Global keyboard shortcuts (⌘K, Escape)
  },
  
  destroyed() {
    // Clean up global event listeners
  },
  
  isVisible() { /* Check if modal is shown */ },
  toggle() { /* Toggle visibility */ },
  show() { /* Show modal, focus input, reset state */ },
  hide() { /* Hide with fade-out animation */ },
  filterResults(query) { /* Filter results and update section visibility */ },
  handleKeydown(e) { /* Arrow navigation and Enter to execute */ },
  updateSelection() { /* Highlight selected result */ },
  executeCommand(result) { /* Navigate or perform action */ }
}
```

#### 3. Helper Functions

- `command_result/1` - Private component for rendering individual command items
- `show_command_bar/1` - Public function that returns Phoenix.LiveView.JS commands to show the modal (used by nav button)

## Data Flow

```
User presses ⌘K
    │
    ▼
Global keydown listener triggers toggle()
    │
    ▼
show() is called
    │
    ├── Set display: flex (show modal)
    ├── Add animation class
    ├── Reset search input
    ├── Reset filter (show all results)
    ├── Reset selection to first item
    └── Focus search input
    │
    ▼
User types to filter
    │
    ▼
filterResults() filters by title/subtitle
    │
    ├── Hide non-matching results
    ├── Hide empty section headers
    └── Reset selection to first visible item
    │
    ▼
User presses Enter or clicks result
    │
    ▼
executeCommand() checks data attributes
    │
    ├── data-href → window.location.href = href
    └── data-action → perform action (e.g., copy URL)
```

## Adding New Commands

### Navigation Command

Add a new `<.command_result>` in the Navigation section:

```heex
<.command_result
  id="cmd-new-page"
  icon="hero-icon-name"
  title="New Page"
  subtitle="Description shown below title"
  href="/new-page"
/>
```

### Action Command

Add a new `<.command_result>` in the Actions section with an `action` attribute instead of `href`:

```heex
<.command_result
  id="cmd-new-action"
  icon="hero-icon-name"
  title="Do Something"
  subtitle="Action description"
  action="action-name"
/>
```

Then handle the action in the `executeCommand` function:

```javascript
executeCommand(result) {
  const href = result.dataset.href;
  const action = result.dataset.action;

  if (href) {
    window.location.href = href;
  } else if (action === "copy-url") {
    navigator.clipboard.writeText(window.location.href);
    this.hide();
  } else if (action === "action-name") {
    // Handle new action
    this.hide();
  }
}
```

## Styling

All styles are in `assets/css/command_bar.css`. Key CSS classes:

| Class | Purpose |
|-------|---------|
| `.commandBarPositioner` | Full-screen backdrop overlay |
| `.commandBarAnimator` | Modal container with slide-down animation |
| `.commandBarSearch` | Search input field |
| `.commandBarSection` | Section header (e.g., "Navigation", "Actions") |
| `.commandBarResult` | Individual command item |
| `.commandBarResultItems` | Flex container for icon + text |
| `.kbar` | Trigger button in nav |
| `.kbarClick` | Keyboard key styling (⌘, K) |

CSS variables (defined in `global.css`):

```css
--command-bar-shadow: rgba(0, 0, 0, 0.8);
--command-bar-animator-background: #1a1c1e;
--command-bar-color: #fff;
--command-bar-search-background: #101114;
--command-bar-result-background: #191a1c;
```

## How It's Integrated

1. **layouts.ex** imports `EventHorizonWeb.CommandBar` and renders `<.command_bar id="command-bar" />` in the `app/1` function
2. **page_components.ex** imports `show_command_bar/1` and uses it on the nav button's `phx-click`
3. The command bar is rendered once per page load and persists across LiveView navigations

## Visibility Control

The component uses inline `style="display: none;"` instead of Tailwind's `hidden` class for reliability. The JS hook manages visibility by:

- Setting `display: flex` to show
- Setting `display: none` to hide
- Adding/removing animation classes for smooth transitions

## Accessibility

- The trigger button has `aria-label="Open command bar"`
- Keyboard navigation is fully supported
- Focus is automatically moved to the search input when opened
