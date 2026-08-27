/* =====================================================================
   JharUdyam — landing page behaviour
   =====================================================================

   ┌───────────────────────────────────────────────────────────────┐
   │  EDIT THESE TWO LINES TO POINT THE BUTTONS AT YOUR REAL LINKS.  │
   └───────────────────────────────────────────────────────────────┘

   APP_DOWNLOAD_URL  → the citizen Android app (.apk) download link.
                       Leave as-is until the APK is published; the
                       "Get the Citizen App" buttons will show a short
                       "coming soon" message instead of a broken link.

   PORTAL_URL        → the deployed Government / University / Industry
                       web portal that "Open Partner Portal" opens.
*/

const APP_DOWNLOAD_URL = "https://github.com/nonsense3/JharUdyam-SIH26043/releases/download/SIH-26043/JharUdyam.apk";
const PORTAL_URL       = "/login";                          // Partner portal login route

/* ===================================================================== */

(function () {
  "use strict";

  const isPlaceholder = (url) => !url || url.indexOf("YOUR_") === 0;

  /* ---- Toast helper (used when a link isn't configured yet) -------- */
  const toastEl = document.getElementById("toast");
  let toastTimer;
  function toast(message) {
    if (!toastEl) { alert(message); return; }
    toastEl.textContent = message;
    toastEl.hidden = false;
    // force reflow so the transition runs even on rapid re-clicks
    void toastEl.offsetWidth;
    toastEl.classList.add("show");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {
      toastEl.classList.remove("show");
      setTimeout(() => { toastEl.hidden = true; }, 300);
    }, 3200);
  }

  /* ---- Wire up the two primary actions ----------------------------- */
  function openApp() {
    if (isPlaceholder(APP_DOWNLOAD_URL)) {
      toast("The JharUdyam citizen app link is coming soon.");
      return;
    }
    window.location.href = APP_DOWNLOAD_URL;   // direct .apk download
  }

  function openPortal() {
    window.location.href = PORTAL_URL;
  }

  document.querySelectorAll(".js-app").forEach((el) => el.addEventListener("click", openApp));
  document.querySelectorAll(".js-portal").forEach((el) => el.addEventListener("click", openPortal));

  /* ---- Mobile navigation toggle ------------------------------------ */
  const toggle = document.getElementById("navToggle");
  const nav = document.getElementById("primaryNav");
  if (toggle && nav) {
    const closeNav = () => { nav.classList.remove("nav-open"); toggle.setAttribute("aria-expanded", "false"); toggle.setAttribute("aria-label", "Open menu"); };
    toggle.addEventListener("click", () => {
      const open = nav.classList.toggle("nav-open");
      toggle.setAttribute("aria-expanded", String(open));
      toggle.setAttribute("aria-label", open ? "Close menu" : "Open menu");
    });
    // close after choosing a destination on mobile
    nav.querySelectorAll("a, button").forEach((el) => el.addEventListener("click", closeNav));
    // close when resizing back up to desktop
    window.addEventListener("resize", () => { if (window.innerWidth > 860) closeNav(); });
  }

  /* ---- Sticky-header shadow on scroll ------------------------------ */
  const header = document.getElementById("siteHeader");
  if (header) {
    const onScroll = () => header.classList.toggle("is-scrolled", window.scrollY > 8);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
  }

  /* ---- Smooth-scroll for in-page anchors (respects reduced motion) - */
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  document.querySelectorAll('a[href^="#"]').forEach((link) => {
    link.addEventListener("click", (e) => {
      const id = link.getAttribute("href");
      if (id === "#" || id.length < 2) return;
      const target = document.querySelector(id);
      if (!target) return;
      e.preventDefault();
      target.scrollIntoView({ behavior: reduceMotion ? "auto" : "smooth", block: "start" });
    });
  });

  /* ---- Gentle scroll-reveal for cards and section heads ------------ */
  const revealTargets = document.querySelectorAll(".section-head, .card, .flow-band, .cta-band");
  if (reduceMotion || !("IntersectionObserver" in window)) {
    revealTargets.forEach((el) => el.classList.add("in"));
  } else {
    revealTargets.forEach((el, i) => {
      el.classList.add("reveal");
      el.style.transitionDelay = (Math.min(i % 4, 3) * 60) + "ms";
    });
    const io = new IntersectionObserver((entries, obs) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) { entry.target.classList.add("in"); obs.unobserve(entry.target); }
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });
    revealTargets.forEach((el) => io.observe(el));
  }

  /* ---- Current year (if referenced anywhere) ----------------------- */
  document.querySelectorAll("[data-year]").forEach((el) => { el.textContent = new Date().getFullYear(); });
})();
