import assert from "node:assert/strict";
import test from "node:test";
import { FooterWaves } from "../../assets/js/hooks/footer_waves.js";

class Element extends EventTarget {
  children = [];
  attributes = new Map();
  dataset = {};
  style = {};

  get childElementCount() {
    return this.children.length;
  }

  appendChild(child) {
    this.children.push(...(child.fragment ? child.children : [child]));
  }

  toggleAttribute(name, enabled) {
    if (enabled) this.attributes.set(name, "");
    else this.attributes.delete(name);
  }

  removeAttribute(name) {
    this.attributes.delete(name);
  }

  hasAttribute(name) {
    return this.attributes.has(name);
  }

  setAttribute(name, value) {
    this.attributes.set(name, String(value));
  }

  replaceChildren() {
    this.children = [];
  }
}

test("footer switches animations, reuses snippets, pauses when inactive, and cleans up", (t) => {
  const document = new EventTarget();
  document.hidden = false;
  document.createElement = () => new Element();
  document.createDocumentFragment = () => Object.assign(new Element(), { fragment: true });
  const motionQuery = Object.assign(new EventTarget(), { matches: true });
  const observers = [];
  class IntersectionObserver {
    constructor(callback) {
      this.callback = callback;
      observers.push(this);
    }
    observe(el) {
      this.el = el;
    }
    disconnect() {
      this.disconnected = true;
    }
    intersect(isIntersecting) {
      this.callback([{ isIntersecting }]);
    }
  }

  const saved = new Map();
  const localStorage = {
    getItem: (key) => saved.get(key),
    setItem: (key, value) => saved.set(key, value),
  };
  const globals = {
    document,
    window: { matchMedia: () => motionQuery, localStorage },
    IntersectionObserver,
  };
  for (const [key, value] of Object.entries(globals)) {
    const original = Object.getOwnPropertyDescriptor(globalThis, key);
    Object.defineProperty(globalThis, key, { configurable: true, value });
    t.after(() => {
      if (original) Object.defineProperty(globalThis, key, original);
      else delete globalThis[key];
    });
  }
  for (const timer of ["setTimeout", "setInterval", "requestAnimationFrame"]) {
    if (timer in globalThis) {
      t.mock.method(globalThis, timer, () => assert.fail("footer must not schedule JS animation work"));
    }
  }

  const createFooter = () => {
    const el = new Element();
    const logo = new Element();
    const controls = new EventTarget();
    const buttons = ["code", "dvd", "nyan"].map((mode) => {
      const button = new Element();
      button.dataset.footerAnimation = mode;
      button.closest = () => button;
      return button;
    });
    controls.querySelectorAll = () => buttons;
    el.parentElement = { querySelector: () => controls };
    el.querySelector = () => logo;
    const click = (mode) => {
      const event = new Event("click");
      Object.defineProperty(event, "target", {
        value: buttons.find((button) => button.dataset.footerAnimation === mode),
      });
      controls.dispatchEvent(event);
    };
    return { hook: { ...FooterWaves, el }, el, logo, buttons, click };
  };
  const { hook, el, logo, buttons, click } = createFooter();
  hook.mounted();
  assert.equal(el.childElementCount, 0, "offscreen mount creates no snippets");
  observers[0].intersect(true);
  assert.equal(el.childElementCount, 0, "reduced motion creates no snippets");
  motionQuery.matches = false;
  motionQuery.dispatchEvent(new Event("change"));
  assert.equal(el.childElementCount, 10);
  assert.ok(el.attributes.has("data-animated"));
  const snippets = [...el.children];

  observers[0].intersect(false);
  assert.ok(!el.attributes.has("data-animated"));
  document.dispatchEvent(new Event("visibilitychange"));
  assert.ok(!el.attributes.has("data-animated"), "visible tab must not wake an offscreen footer");
  observers[0].intersect(true);
  assert.deepEqual(el.children, snippets, "scrolling back reuses the same pool");
  document.hidden = true;
  document.dispatchEvent(new Event("visibilitychange"));
  assert.ok(!el.attributes.has("data-animated"));
  document.hidden = false;
  document.dispatchEvent(new Event("visibilitychange"));
  assert.ok(el.attributes.has("data-animated"));
  motionQuery.matches = true;
  motionQuery.dispatchEvent(new Event("change"));
  assert.ok(!el.attributes.has("data-animated"));

  motionQuery.matches = false;
  motionQuery.dispatchEvent(new Event("change"));
  click("dvd");
  assert.equal(el.dataset.animation, "dvd");
  assert.equal(saved.get("footer-animation"), "dvd");
  assert.equal(buttons[0].attributes.get("aria-pressed"), "false");
  assert.equal(buttons[1].attributes.get("aria-pressed"), "true");
  assert.deepEqual(el.children, snippets, "switching preserves the snippet pool");

  const bounce = (name) => {
    const event = new Event("animationiteration");
    Object.defineProperty(event, "animationName", { value: name });
    el.dispatchEvent(event);
  };
  bounce("floatUp");
  assert.equal(logo.style.color, undefined);
  bounce("dvdX");
  assert.equal(logo.style.color, "var(--theme-two)");
  bounce("dvdY");
  assert.equal(logo.style.color, "var(--theme-three)");
  observers[0].intersect(false);
  bounce("dvdX");
  assert.equal(logo.style.color, "var(--theme-three)", "paused DVD must not update color");
  observers[0].intersect(true);
  click("code");
  assert.equal(el.dataset.animation, "code");
  assert.deepEqual(el.children, snippets);
  click("nyan");
  assert.equal(el.dataset.animation, "nyan");
  assert.equal(saved.get("footer-animation"), "nyan");
  assert.equal(buttons[2].attributes.get("aria-pressed"), "true");
  assert.equal(buttons[1].attributes.get("aria-pressed"), "false");
  assert.deepEqual(el.children, snippets, "Nyan Cat reuses the existing footer nodes");
  observers[0].intersect(false);
  assert.ok(!el.hasAttribute("data-animated"), "Nyan Cat pauses offscreen");
  observers[0].intersect(true);
  document.hidden = true;
  document.dispatchEvent(new Event("visibilitychange"));
  assert.ok(!el.hasAttribute("data-animated"), "Nyan Cat pauses in a hidden tab");
  document.hidden = false;
  document.dispatchEvent(new Event("visibilitychange"));
  assert.ok(el.hasAttribute("data-animated"));
  click("dvd");

  hook.destroyed();
  assert.ok(observers[0].disconnected);
  assert.equal(el.childElementCount, 0);
  motionQuery.matches = false;
  motionQuery.dispatchEvent(new Event("change"));
  document.dispatchEvent(new Event("visibilitychange"));
  assert.equal(el.childElementCount, 0, "destroyed hooks cannot recreate snippets");
  assert.ok(!el.attributes.has("data-animated"));
  click("code");
  bounce("dvdX");
  assert.equal(el.dataset.animation, "dvd", "destroy removes the selection listener");
  assert.equal(logo.style.color, "var(--theme-three)");

  const nextFooter = createFooter();
  const next = nextFooter.hook;
  next.mounted();
  assert.equal(next.el.dataset.animation, "dvd", "navigation restores the chosen animation");
  assert.equal(next.el.childElementCount, 0);
  observers[1].intersect(true);
  assert.equal(next.el.childElementCount, 0, "DVD must not create code snippets");
  assert.ok(next.el.hasAttribute("data-animated"));
  t.mock.method(localStorage, "setItem", () => {
    throw new Error("storage blocked");
  });
  nextFooter.click("code");
  assert.equal(next.el.childElementCount, 10, "navigation cannot exceed the pool limit");
  assert.equal(el.childElementCount, 0, "navigation cannot mutate the old footer");
  next.destroyed();

  saved.set("footer-animation", "nyan");
  const nyan = createFooter().hook;
  nyan.mounted();
  assert.equal(nyan.el.dataset.animation, "nyan", "navigation restores Nyan Cat");
  observers.at(-1).intersect(true);
  assert.equal(nyan.el.childElementCount, 0, "Nyan Cat creates no code snippets");
  motionQuery.matches = true;
  motionQuery.dispatchEvent(new Event("change"));
  assert.ok(!nyan.el.hasAttribute("data-animated"), "Nyan Cat respects reduced motion");
  nyan.destroyed();

  saved.set("footer-animation", "winamp");
  const removed = createFooter().hook;
  removed.mounted();
  assert.equal(removed.el.dataset.animation, "code", "removed modes fall back to Code");
  removed.destroyed();

  t.mock.method(localStorage, "getItem", () => {
    throw new Error("storage blocked");
  });
  const fallback = createFooter().hook;
  fallback.mounted();
  assert.equal(fallback.el.dataset.animation, "code");
  fallback.destroyed();
});
