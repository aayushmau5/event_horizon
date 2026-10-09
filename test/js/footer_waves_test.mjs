import assert from "node:assert/strict";
import test from "node:test";
import { FooterWaves } from "../../assets/js/hooks/footer_waves.js";

class Element {
  children = [];
  attributes = new Set();
  style = {};

  get childElementCount() {
    return this.children.length;
  }

  appendChild(child) {
    this.children.push(...(child.fragment ? child.children : [child]));
  }

  toggleAttribute(name, enabled) {
    if (enabled) this.attributes.add(name);
    else this.attributes.delete(name);
  }

  removeAttribute(name) {
    this.attributes.delete(name);
  }

  replaceChildren() {
    this.children = [];
  }
}

test("footer reuses a bounded pool, pauses when inactive, and cleans up on navigation", (t) => {
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

  const globals = { document, window: { matchMedia: () => motionQuery }, IntersectionObserver };
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

  const el = new Element();
  const hook = { ...FooterWaves, el };
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

  hook.destroyed();
  assert.ok(observers[0].disconnected);
  assert.equal(el.childElementCount, 0);
  motionQuery.matches = false;
  motionQuery.dispatchEvent(new Event("change"));
  document.dispatchEvent(new Event("visibilitychange"));
  assert.equal(el.childElementCount, 0, "destroyed hooks cannot recreate snippets");
  assert.ok(!el.attributes.has("data-animated"));

  const next = { ...FooterWaves, el: new Element() };
  next.mounted();
  assert.equal(next.el.childElementCount, 0);
  observers[1].intersect(true);
  assert.equal(next.el.childElementCount, 10, "navigation cannot exceed the pool limit");
  assert.equal(el.childElementCount, 0, "navigation cannot mutate the old footer");
  next.destroyed();
});
