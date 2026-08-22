// English copy is kept here to retain a single source for the site text.
// and the markup keeps only its default copy. Elements opt in with data-i18n
// (inner HTML), data-i18n-aria (aria-label) or data-i18n-alt (image alt).
const translations = {
  en: {
    'meta.title': 'Nocket: Keep the good stuff in reach.',
    'meta.description': 'Nocket turns your MacBook notch into a fast, visual clipboard shelf.',

    'nav.idea': 'The idea',
    'nav.inside': 'Inside Nocket',
    'nav.faq': 'FAQ',
    'nav.langAria': 'Switch language',
    'nav.download': 'Download',
    'nav.downloadMac': 'Download for macOS',
    'nav.menu': 'Menu',
    'nav.closeMenu': 'Close menu',

    'hero.title': 'Keep the good<br /><em>stuff in reach.</em>',
    'hero.lead': 'Nocket keeps the things you copy close by, so you can find a sentence, link, color, or file again without breaking your flow.',
    'hero.cta': 'Download for macOS',
    'hero.mockupAria': 'Nocket MacBook mockup',
    'hero.mockupAlt': 'MacBook mockup showing Nocket',

    'overlay.label': 'CLIPBOARD',
    'overlay.title': 'Keep the good<br />stuff in reach.',
    'overlay.search': 'Search your clipboard',
    'overlay.itemOne': 'Launch notes',
    'overlay.itemOneTime': 'now',
    'overlay.itemTwo': 'Design handoff in Figma',
    'overlay.itemTwoTime': '3m',

    'intro.title': 'One small place<br />for the things you <em>reuse.</em>',
    'intro.lead': 'Nocket turns your clipboard into a quiet visual layer above the work. Open it with a gesture, search by memory, and paste without losing your train of thought.',
    'tag.history': '◒ Visual history',
    'tag.shelf': '⌁ Notch shelf',
    'tag.search': '⌘ Quick search',
    'tag.drag': '↗ Drag anything',
    'tag.shots': '◌ Screenshots',
    'tag.collections': '✦ Collections',

    'features.title': 'Make room for<br />the things you<br /><em>reach for.</em>',
    'features.lead': 'The shelf expands above your current app instead of pulling you into another window. A color from Figma, a link from Safari or a snippet from Terminal: everything is ready when the thought comes back.',
    'wide.search': '⌕ Search your memory',
    'wide.all': 'All',
    'wide.text': 'Text 12',
    'wide.links': 'Links 18',
    'wide.images': 'Images 8',
    'wide.colors': 'Colors 5',
    'wide.code': 'Code 21',
    'clip.one': 'Hi, {name},<br />just following up on my...',
    'clip.oneMeta': 'Chrome · 1 min ago',
    'clip.two': 'Morning<br />reference',
    'clip.twoMeta': 'Figma · 3 min ago',
    'clip.threeMeta': 'Color · 6 min ago',
    'clip.fourMeta': 'Color · 8 min ago',
    'clip.five': '⌘<br />Quick note',
    'clip.fiveMeta': 'Notes · 12 min ago',

    'reverse.title': 'Copy. Return.<br />Pick up<br /><em>where you left off.</em>',
    'reverse.lead': 'Text, links, screenshots, images, code, colors, and files become a visual trail of your work. Drag an item into the app in front of you, or paste it with one click.',
    'notch.search': 'Search your memory',
    'notch.all': 'All',
    'notch.colors': 'Colors',
    'notch.assets': 'Assets',
    'notch.snippets': 'Snippets',
    'notch.idea': 'Idea',
    'notch.note': 'Note',
    'notch.color': 'Color',

    'quote.text': '“I stop asking myself where I put that link. Nocket gives the answer without making me leave the app I’m in.”',
    'quote.role': 'Product designer',

    'use.title': 'For the work<br />between <em>tabs.</em>',
    'use.lead': 'Nocket is for the little pieces that keep a day moving: the reference you found, the reply you wrote, the color you liked, the command you’ll need again.',
    'use.oneTitle': 'Visual work',
    'use.oneBody': 'Keep colors, screenshots, SVGs, gradients, references, and assets close at hand.',
    'use.twoTitle': 'Deep work',
    'use.twoBody': 'Save code snippets, commands, errors, JSON, API responses, and links automatically.',
    'use.threeTitle': 'Words in progress',
    'use.threeBody': 'Capture hooks, taglines, drafts, research links, and all the phrases worth keeping.',
    'use.fourTitle': 'Research mode',
    'use.fourBody': 'Collect product ideas, competitor screenshots, notes, and daily references without clutter.',
    'use.fiveTitle': 'Repeat work',
    'use.fiveBody': 'Reuse your best replies, email templates, customer notes, and support screenshots.',
    'use.sixTitle': 'Life outside work',
    'use.sixBody': 'Find addresses, recipes, links, quotes, images, and anything you meant to save.',

    'oss.eyebrow': 'Open source · MIT',
    'oss.title': 'Free.<br /><em>And open source.</em>',
    'oss.lead': 'No subscription, no license key, no catch. Nocket is MIT licensed. Read the code, change it, or just use it.',
    'oss.cta': 'Download for macOS',
    'oss.source': 'View source',
    'oss.metaOne': 'macOS 14+',
    'oss.metaTwo': 'Apple silicon and Intel',
    'oss.metaThree': 'Nothing leaves your Mac',

    'faq.title': 'Frequently asked<br /><em>questions.</em>',
    'faq.lead': 'Everything you need to know about the Nocket notch shelf, privacy, compatibility, and clipboard storage.',
    'faq.oneQ': 'How does the notch shelf work?',
    'faq.oneA': 'Move your pointer to the MacBook notch or use the keyboard shortcut. Nocket expands above your current app, then closes when you’re done.',
    'faq.twoQ': 'Does Nocket upload my copied content?',
    'faq.twoA': 'No. Your clipboard history stays on your Mac. Nocket is local first and private by default.',
    'faq.threeQ': 'What types of content does Nocket support?',
    'faq.threeA': 'Text, links, screenshots, images, code, colors, and files, all organized in a visual history.',
    'faq.fourQ': 'Can I use Nocket without a notch?',
    'faq.fourA': 'Yes. The notch shelf is the signature experience, while a keyboard shortcut keeps Nocket fast on Macs with any display.',
    'faq.fiveQ': 'Which Macs are supported?',
    'faq.fiveA': 'Nocket is being built for modern Macs running macOS Sonoma 14 or later.',
    'faq.sixQ': 'Is Nocket a subscription?',
    'faq.sixA': 'No. Nocket is free and open source under the MIT license: no payment, no account, no catch.',

    'dl.title': 'Your clipboard.<br /><em>One glance away.</em>',
    'dl.lead': 'Turn the top of your Mac into the fastest place to find anything you copied.',
    'dl.cta': 'Download',
    'dl.actionsAria': 'Nocket links',
    'dl.xAria': 'Nocket on X',
    'dl.note': 'macOS Sonoma 14 or later · Latest build',

    'footer.tagline': 'notch clipboard',
    'footer.title': 'Your clipboard.<br /><em>Right in the notch.</em>',
    'footer.lead': 'Nocket turns the top of your Mac into a private, visual shelf for everything you copy.',
    'footer.cta': 'Download the app',
    'footer.copy': '© 2026 Nocket. All rights reserved.',
    'footer.menu': 'Menu',
    'footer.home': 'Home',
    'footer.notch': 'The notch',
    'footer.features': 'Features',
    'footer.faq': 'FAQ',
    'footer.nav': 'Navigation',
    'footer.useCases': 'Use cases',
    'footer.download': 'Download',
    'footer.contact': 'Contact',
    'footer.more': 'More',
    'footer.privacy': 'Privacy',
    'footer.terms': 'Terms',
    'footer.top': 'Back to top ↑',

    'legal.kicker': 'Nocket · Legal',
    'legal.local': 'Local first',
    'legal.open': 'Open source',
    'legal.onThisPage': 'On this page',
    'legal.overview': 'Overview',
    'legal.summary': 'Summary',
    'legal.current': 'Current',
    'legal.back': '← Back to Nocket',
    'legal.ctaLabel': 'Back to the useful stuff',
    'legal.ctaTitle': 'Keep the good stuff<br /><em>in reach.</em>',
    'legal.ctaBody': 'Your clipboard, one glance away.',
    'privacy.metaTitle': 'Nocket: Privacy',
    'privacy.eyebrow': 'Privacy',
    'privacy.title': 'Your clipboard stays on your Mac.',
    'privacy.body': 'Nocket is local first. Your clipboard history is stored on your device and is never uploaded to a Nocket server. This page stands in for the full privacy policy.',
    'privacy.summaryTitle': 'A private layer above your work.',
    'privacy.summaryBody': 'Nocket keeps clipboard history close to the work, on the Mac where you created it.',
    'privacy.pointOneTitle': 'Stored on your Mac.',
    'privacy.pointOneBody': 'Your clipboard history stays on your device.',
    'privacy.pointTwoTitle': 'No Nocket server.',
    'privacy.pointTwoBody': 'Copied content is not uploaded to a Nocket server.',
    'privacy.pointThreeTitle': 'Private by default.',
    'privacy.pointThreeBody': 'The local-first approach keeps the experience quiet and focused.',
    'privacy.noteTitle': 'Local by default.',
    'privacy.noteBody': 'Nocket is designed to keep the things you copy close at hand without sending them away.',
    'terms.metaTitle': 'Nocket: Terms',
    'terms.eyebrow': 'Terms',
    'terms.title': 'Simple software, clear terms.',
    'terms.body': 'Nocket is provided as open source software under the MIT license. This page stands in for the full terms of service.',
    'terms.summaryTitle': 'Open source software, with a simple foundation.',
    'terms.summaryBody': 'Nocket is offered as open source software under the MIT license.',
    'terms.pointOneTitle': 'MIT licensed.',
    'terms.pointOneBody': 'The project is available under the MIT license.',
    'terms.pointTwoTitle': 'No subscription.',
    'terms.pointTwoBody': 'Nocket is free to use, with no account or recurring payment.',
    'terms.pointThreeTitle': 'Use it your way.',
    'terms.pointThreeBody': 'Read the code, change it, or just use the app.',
    'terms.noteTitle': 'Simple by design.',
    'terms.noteBody': 'Nocket keeps the product and its terms straightforward: open source, local first, and easy to understand.'
  }
};

const defaultLanguage = 'en';
let currentLanguage = defaultLanguage;
const t = (key) => translations[currentLanguage]?.[key] ?? translations[defaultLanguage][key] ?? '';

const menuToggle = document.querySelector('.menu-toggle');
const mainNav = document.querySelector('.mobile-nav');
const notchNav = document.querySelector('[data-notch-nav]');
const notchPeekToggle = document.querySelector('.notch-peek-toggle');
const notchNavShelf = document.querySelector('#notch-nav-shelf');
const supportsHover = window.matchMedia('(hover: hover) and (pointer: fine)').matches;
let notchShelfPinned = false;
let notchOpenTimer;
let notchCloseTimer;

const setNotchShelf = (open, pinned = notchShelfPinned) => {
  notchShelfPinned = pinned && open;
  notchNav?.classList.toggle('is-expanded', open);
  notchNav?.classList.toggle('is-pinned', notchShelfPinned);
  notchPeekToggle?.setAttribute('aria-expanded', String(open));
  notchNavShelf?.setAttribute('aria-hidden', String(!open));
};

const cancelNotchTimers = () => {
  window.clearTimeout(notchOpenTimer);
  window.clearTimeout(notchCloseTimer);
};

notchPeekToggle?.addEventListener('click', (event) => {
  event.stopPropagation();
  cancelNotchTimers();
  const nextOpen = !notchNav?.classList.contains('is-expanded') || !notchShelfPinned;
  setNotchShelf(nextOpen, nextOpen);
  setMobileMenu(false);
});

if (supportsHover) {
  notchNav?.addEventListener('pointerenter', () => {
    cancelNotchTimers();
    if (!notchShelfPinned) notchOpenTimer = window.setTimeout(() => setNotchShelf(true, false), 120);
  });

  notchNav?.addEventListener('pointerleave', () => {
    cancelNotchTimers();
    if (!notchShelfPinned) notchCloseTimer = window.setTimeout(() => setNotchShelf(false, false), 180);
  });
}

notchNav?.addEventListener('focusin', () => {
  cancelNotchTimers();
  if (!notchShelfPinned) setNotchShelf(true, false);
});

notchNav?.addEventListener('focusout', () => {
  window.setTimeout(() => {
    if (!notchShelfPinned && !notchNav?.contains(document.activeElement)) setNotchShelf(false, false);
  }, 0);
});

const drawerClose = mainNav?.querySelector('.drawer-close');

const setMobileMenu = (open) => {
  mainNav?.classList.toggle('is-open', open);
  menuToggle?.classList.toggle('is-open', open);
  document.body.classList.toggle('mobile-menu-open', open);
  menuToggle?.setAttribute('aria-expanded', String(open));
  menuToggle?.setAttribute('aria-label', open ? 'Close menu' : 'Menu');
  // focusul intra in panou la deschidere si se intoarce pe buton la inchidere
  if (open) drawerClose?.focus();
  else if (mainNav?.contains(document.activeElement)) menuToggle?.focus();
};

drawerClose?.addEventListener('click', () => setMobileMenu(false));

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape' && mainNav?.classList.contains('is-open')) setMobileMenu(false);
});

menuToggle?.addEventListener('click', () => {
  setNotchShelf(false, false);
  setMobileMenu(!mainNav?.classList.contains('is-open'));
});

mainNav?.querySelectorAll('a').forEach((link) => {
  link.addEventListener('click', () => {
    setMobileMenu(false);
  });
});

document.addEventListener('click', (event) => {
  if (notchShelfPinned && !notchNav?.contains(event.target)) setNotchShelf(false, false);
  if (!mainNav?.classList.contains('is-open')) return;
  if (mainNav.contains(event.target) || menuToggle?.contains(event.target)) return;
  setMobileMenu(false);
});

const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const heroSection = document.querySelector('.hero');
let shelfJourneyFrame = false;

const updateShelfJourney = () => {
  shelfJourneyFrame = false;
  if (!heroSection || reducedMotion) return;
  const heroRect = heroSection.getBoundingClientRect();
  const distance = Math.max(0, -heroRect.top);
  const progress = Math.min(1, distance / (heroSection.offsetHeight * 0.58));
  const maximumShift = window.innerWidth <= 600 ? 22 : window.innerWidth <= 850 ? 38 : 54;
  heroSection.style.setProperty('--shelf-shift', `${(progress * maximumShift).toFixed(1)}px`);
  heroSection.style.setProperty('--shelf-scale', (1 - progress * 0.038).toFixed(3));
  heroSection.style.setProperty('--handoff-opacity', (1 - progress * 0.28).toFixed(3));
};

const requestShelfJourneyUpdate = () => {
  if (shelfJourneyFrame) return;
  shelfJourneyFrame = true;
  window.requestAnimationFrame(updateShelfJourney);
};

if (!reducedMotion && heroSection) {
  updateShelfJourney();
  window.addEventListener('scroll', requestShelfJourneyUpdate, { passive: true });
  window.addEventListener('resize', requestShelfJourneyUpdate);
}

const revealTargets = document.querySelectorAll([
  '.intro > *',
  '.feature-panel',
  '.testimonial > *',
  '.audiences > h2',
  '.audiences > p',
  '.audience-grid article',
  '.pricing-inner > h2',
  '.pricing-inner > p',
  '.price-card',
  '.faq > h2',
  '.faq > p',
  '.faq-grid details',
  '.download-inner > *',
  '.legal-sidebar > *',
  '.legal-article > *',
  '.legal-cta-inner > *',
  '.footer-inner > *'
].join(','));

revealTargets.forEach((element, index) => {
  element.classList.add('reveal');
  element.style.setProperty('--reveal-delay', `${(index % 6) * 65}ms`);
});

if (reducedMotion || !('IntersectionObserver' in window)) {
  revealTargets.forEach((element) => element.classList.add('is-visible'));
} else {
  const revealObserver = new IntersectionObserver((entries, observer) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      entry.target.classList.add('is-visible');
      observer.unobserve(entry.target);
    });
  }, { rootMargin: '0px 0px -8% 0px', threshold: 0.12 });

  revealTargets.forEach((element) => revealObserver.observe(element));
}

document.querySelectorAll('.filter, .device-pills span').forEach((pill) => {
  pill.addEventListener('click', () => {
    document.querySelectorAll('.filter, .device-pills span, .device-pills b').forEach((item) => item.classList.remove('selected'));
    pill.classList.add('selected');
  });
});

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') {
    setMobileMenu(false);
    setNotchShelf(false, false);
  }
});

document.querySelectorAll('.download-arrow').forEach((arrow) => arrow.remove());

// Keep the FAQ focused and animate both opening and closing.
const faqItems = document.querySelectorAll('.faq-grid details');
const faqAnimationDuration = 340;
const faqCloseTimers = new WeakMap();

const closeFaqItem = (item) => {
  window.clearTimeout(faqCloseTimers.get(item));
  item.classList.remove('is-expanded');
  item.classList.add('is-collapsing');
  const timer = window.setTimeout(() => {
    item.open = false;
    window.setTimeout(() => item.classList.remove('is-collapsing'), 0);
  }, faqAnimationDuration);
  faqCloseTimers.set(item, timer);
};

faqItems.forEach((item) => {
  if (item.open) window.requestAnimationFrame(() => item.classList.add('is-expanded'));
  item.addEventListener('toggle', () => {
    if (item.classList.contains('is-collapsing')) return;
    if (item.open) {
      faqItems.forEach((otherItem) => {
        if (otherItem !== item && otherItem.open && !otherItem.classList.contains('is-collapsing')) closeFaqItem(otherItem);
      });
      window.requestAnimationFrame(() => item.classList.add('is-expanded'));
      return;
    }

    item.open = true;
    closeFaqItem(item);
  });
});

// Scroll-driven motion for the dependency-free MacBook hero preview.
(() => {
  const stage = document.querySelector('[data-macbook-scroll]');
  const lid = document.querySelector('[data-macbook-lid]');
  const base = document.querySelector('[data-macbook-base]');
  if (!stage || !lid || !base || reducedMotion) return;

  let frame = false;
  const updateMacbook = () => {
    frame = false;
    const rect = stage.getBoundingClientRect();
    const travel = Math.max(window.innerHeight * 0.65, 420);
    const progress = Math.min(1, Math.max(0, (window.innerHeight - rect.top) / travel));
    const lidAngle = -19 + progress * 19;
    const lidLift = progress * 46;
    const baseAngle = 10 - progress * 10;
    lid.style.transform = `rotateX(${lidAngle.toFixed(2)}deg) translateY(${lidLift.toFixed(1)}px)`;
    base.style.transform = `perspective(1250px) rotateX(${baseAngle.toFixed(2)}deg)`;
  };

  const requestMacbookUpdate = () => {
    if (frame) return;
    frame = true;
    window.requestAnimationFrame(updateMacbook);
  };

  updateMacbook();
  window.addEventListener('scroll', requestMacbookUpdate, { passive: true });
  window.addEventListener('resize', requestMacbookUpdate);
})();

(() => {
  const imageMockup = document.querySelector('[data-macbook-image]');
  if (!imageMockup || reducedMotion) return;
  let frame = false;
  const updateImageMockup = () => {
    frame = false;
    const rect = imageMockup.getBoundingClientRect();
    const progress = Math.min(1, Math.max(0, (window.innerHeight - rect.top) / Math.max(window.innerHeight * 0.8, 500)));
    imageMockup.style.transform = `translateY(${(progress * 28).toFixed(1)}px) scale(${(1 - progress * 0.018).toFixed(3)})`;
  };
  const requestImageUpdate = () => {
    if (frame) return;
    frame = true;
    window.requestAnimationFrame(updateImageMockup);
  };
  updateImageMockup();
  window.addEventListener('scroll', requestImageUpdate, { passive: true });
  window.addEventListener('resize', requestImageUpdate);
})();
