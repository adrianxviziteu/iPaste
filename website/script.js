// Every string the site shows lives here, so English and Romanian stay in sync
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

    'legal.back': '← Back to Nocket',
    'privacy.metaTitle': 'Nocket: Privacy',
    'privacy.eyebrow': 'Privacy',
    'privacy.title': 'Your clipboard stays on your Mac.',
    'privacy.body': 'Nocket is local first. Your clipboard history is stored on your device and is never uploaded to a Nocket server. This page stands in for the full privacy policy.',
    'terms.metaTitle': 'Nocket: Terms',
    'terms.eyebrow': 'Terms',
    'terms.title': 'Simple software, clear terms.',
    'terms.body': 'Nocket is provided as open source software under the MIT license. This page stands in for the full terms of service.'
  },
  ro: {
    'meta.title': 'Nocket: Ține la îndemână ce contează.',
    'meta.description': 'Nocket transformă notch-ul de pe MacBook într-un raft vizual și rapid pentru clipboard.',

    'nav.idea': 'Ideea',
    'nav.inside': 'În Nocket',
    'nav.faq': 'Întrebări',
    'nav.langAria': 'Schimbă limba',
    'nav.download': 'Descarcă',
    'nav.downloadMac': 'Descarcă pentru macOS',
    'nav.menu': 'Meniu',
    'nav.closeMenu': 'Închide meniul',

    'hero.title': 'Ține la îndemână<br /><em>ce contează.</em>',
    'hero.lead': 'Nocket păstrează aproape lucrurile pe care le copiezi, ca să regăsești o frază, un link, o culoare sau un fișier fără să îți pierzi ritmul.',
    'hero.cta': 'Descarcă pentru macOS',
    'hero.mockupAria': 'Machetă de MacBook cu Nocket',
    'hero.mockupAlt': 'Machetă de MacBook care arată Nocket',

    'overlay.label': 'CLIPBOARD',
    'overlay.title': 'Ține la îndemână<br />ce contează.',
    'overlay.search': 'Caută în clipboard',
    'overlay.itemOne': 'Notițe de lansare',
    'overlay.itemOneTime': 'acum',
    'overlay.itemTwo': 'Predare de design în Figma',
    'overlay.itemTwoTime': '3m',

    'intro.title': 'Un loc mic<br />pentru lucrurile pe care le <em>refolosești.</em>',
    'intro.lead': 'Nocket transformă clipboard-ul într-un strat vizual și discret peste munca ta. Îl deschizi dintr-un gest, cauți după memorie și lipești fără să pierzi firul gândului.',
    'tag.history': '◒ Istoric vizual',
    'tag.shelf': '⌁ Raft în notch',
    'tag.search': '⌘ Căutare rapidă',
    'tag.drag': '↗ Trage orice',
    'tag.shots': '◌ Capturi de ecran',
    'tag.collections': '✦ Colecții',

    'features.title': 'Fă loc pentru<br />lucrurile la care<br /><em>revii.</em>',
    'features.lead': 'Raftul se deschide peste aplicația curentă, în loc să te ducă într-o altă fereastră. O culoare din Figma, un link din Safari sau un fragment din Terminal: totul e pregătit când îți revine gândul.',
    'wide.search': '⌕ Caută în memorie',
    'wide.all': 'Toate',
    'wide.text': 'Text 12',
    'wide.links': 'Linkuri 18',
    'wide.images': 'Imagini 8',
    'wide.colors': 'Culori 5',
    'wide.code': 'Cod 21',
    'clip.one': 'Bună, {name},<br />revin cu privire la...',
    'clip.oneMeta': 'Chrome · acum 1 min',
    'clip.two': 'Referință<br />de dimineață',
    'clip.twoMeta': 'Figma · acum 3 min',
    'clip.threeMeta': 'Culoare · acum 6 min',
    'clip.fourMeta': 'Culoare · acum 8 min',
    'clip.five': '⌘<br />Notiță rapidă',
    'clip.fiveMeta': 'Notițe · acum 12 min',

    'reverse.title': 'Copiezi. Revii.<br />Continui<br /><em>de unde ai rămas.</em>',
    'reverse.lead': 'Textele, linkurile, capturile, imaginile, codul, culorile și fișierele devin o urmă vizuală a muncii tale. Tragi un element în aplicația din față sau îl lipești dintr-un singur click.',
    'notch.search': 'Caută în memorie',
    'notch.all': 'Toate',
    'notch.colors': 'Culori',
    'notch.assets': 'Resurse',
    'notch.snippets': 'Fragmente',
    'notch.idea': 'Idee',
    'notch.note': 'Notiță',
    'notch.color': 'Culoare',

    'quote.text': '„Nu mă mai întreb unde am pus linkul acela. Nocket îmi dă răspunsul fără să ies din aplicația în care lucrez.”',
    'quote.role': 'Designer de produs',

    'use.title': 'Pentru munca<br />dintre <em>tab-uri.</em>',
    'use.lead': 'Nocket e pentru bucățile mici care țin ziua în mișcare: referința pe care ai găsit-o, răspunsul pe care l-ai scris, culoarea care ți-a plăcut, comanda de care vei mai avea nevoie.',
    'use.oneTitle': 'Lucru vizual',
    'use.oneBody': 'Ține la îndemână culori, capturi, fișiere SVG, gradiente, referințe și alte resurse.',
    'use.twoTitle': 'Muncă de concentrare',
    'use.twoBody': 'Salvează automat fragmente de cod, comenzi, erori, JSON, răspunsuri de API și linkuri.',
    'use.threeTitle': 'Cuvinte în lucru',
    'use.threeBody': 'Prinde titluri, sloganuri, ciorne, linkuri de documentare și toate frazele care merită păstrate.',
    'use.fourTitle': 'Mod cercetare',
    'use.fourBody': 'Adună idei de produs, capturi de la concurență, notițe și referințe zilnice, fără dezordine.',
    'use.fiveTitle': 'Lucru repetitiv',
    'use.fiveBody': 'Refolosește cele mai bune răspunsuri, șabloane de email, notițe despre clienți și capturi pentru suport.',
    'use.sixTitle': 'Viața de după program',
    'use.sixBody': 'Găsește adrese, rețete, linkuri, citate, imagini și orice ai vrut să păstrezi.',

    'oss.eyebrow': 'Sursă deschisă · MIT',
    'oss.title': 'Gratuit.<br /><em>Și open source.</em>',
    'oss.lead': 'Fără abonament, fără cheie de licență, fără capcane. Nocket are licență MIT. Citește codul, modifică-l sau doar folosește aplicația.',
    'oss.cta': 'Descarcă pentru macOS',
    'oss.source': 'Vezi codul',
    'oss.metaOne': 'macOS 14+',
    'oss.metaTwo': 'Apple silicon și Intel',
    'oss.metaThree': 'Nimic nu pleacă de pe Mac-ul tău',

    'faq.title': 'Întrebări<br /><em>frecvente.</em>',
    'faq.lead': 'Tot ce trebuie să știi despre raftul din notch, confidențialitate, compatibilitate și istoricul clipboard-ului.',
    'faq.oneQ': 'Cum funcționează raftul din notch?',
    'faq.oneA': 'Duci cursorul la notch-ul MacBook-ului sau folosești scurtătura de tastatură. Nocket se deschide peste aplicația curentă, apoi se închide când ai terminat.',
    'faq.twoQ': 'Nocket trimite undeva ce copiez?',
    'faq.twoA': 'Nu. Istoricul clipboard-ului rămâne pe Mac-ul tău. Nocket lucrează local și este privat în mod implicit.',
    'faq.threeQ': 'Ce tipuri de conținut acceptă Nocket?',
    'faq.threeA': 'Text, linkuri, capturi de ecran, imagini, cod, culori și fișiere, toate organizate într-un istoric vizual.',
    'faq.fourQ': 'Pot folosi Nocket fără notch?',
    'faq.fourA': 'Da. Raftul din notch este experiența care definește aplicația, iar scurtătura de tastatură ține Nocket la fel de rapid pe Mac-uri cu orice ecran.',
    'faq.fiveQ': 'Ce Mac-uri sunt compatibile?',
    'faq.fiveA': 'Nocket este construit pentru Mac-uri moderne, cu macOS Sonoma 14 sau mai nou.',
    'faq.sixQ': 'Nocket se plătește prin abonament?',
    'faq.sixA': 'Nu. Nocket este gratuit și open source, sub licență MIT: fără plată, fără cont, fără capcane.',

    'dl.title': 'Clipboard-ul tău.<br /><em>La o privire distanță.</em>',
    'dl.lead': 'Transformă partea de sus a Mac-ului în cel mai rapid loc în care găsești orice ai copiat.',
    'dl.cta': 'Descarcă',
    'dl.actionsAria': 'Linkuri Nocket',
    'dl.xAria': 'Nocket pe X',
    'dl.note': 'macOS Sonoma 14 sau mai nou · Ultima versiune',

    'footer.tagline': 'clipboard în notch',
    'footer.title': 'Clipboard-ul tău.<br /><em>Chiar în notch.</em>',
    'footer.lead': 'Nocket transformă partea de sus a Mac-ului într-un raft vizual și privat pentru tot ce copiezi.',
    'footer.cta': 'Descarcă aplicația',
    'footer.copy': '© 2026 Nocket. Toate drepturile rezervate.',
    'footer.menu': 'Meniu',
    'footer.home': 'Acasă',
    'footer.notch': 'Notch-ul',
    'footer.features': 'Funcții',
    'footer.faq': 'Întrebări',
    'footer.nav': 'Navigare',
    'footer.useCases': 'Cazuri de folosire',
    'footer.download': 'Descarcă',
    'footer.contact': 'Contact',
    'footer.more': 'Altele',
    'footer.privacy': 'Confidențialitate',
    'footer.terms': 'Termeni',
    'footer.top': 'Înapoi sus ↑',

    'legal.back': '← Înapoi la Nocket',
    'privacy.metaTitle': 'Nocket: Confidențialitate',
    'privacy.eyebrow': 'Confidențialitate',
    'privacy.title': 'Clipboard-ul tău rămâne pe Mac-ul tău.',
    'privacy.body': 'Nocket lucrează local. Istoricul clipboard-ului este păstrat pe dispozitivul tău și nu este încărcat pe un server Nocket. Această pagină ține locul politicii de confidențialitate complete.',
    'terms.metaTitle': 'Nocket: Termeni',
    'terms.eyebrow': 'Termeni',
    'terms.title': 'Software simplu, termeni clari.',
    'terms.body': 'Nocket este oferit ca software open source, sub licența MIT. Această pagină ține locul termenilor de utilizare compleți.'
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
  menuToggle?.setAttribute('aria-label', open ? t('nav.closeMenu') : t('nav.menu'));
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

// Keep the product language switch close to the visual system, so the same
// page can be read in English or Romanian without a second layout.
(() => {
  const toggle = document.querySelector('[data-lang-toggle]');
  if (!toggle) return;

  // Round flag marks, drawn inline so the switch never falls back to emoji.
  // Add a language by appending an entry here plus its `strings` block above.
  const flags = {
    en: '<svg viewBox="0 0 60 60" aria-hidden="true" focusable="false"><clipPath id="fc-en"><circle cx="30" cy="30" r="30"/></clipPath><g clip-path="url(#fc-en)"><rect width="60" height="60" fill="#fff"/><g fill="#B22234"><rect width="60" height="4.62"/><rect y="9.23" width="60" height="4.62"/><rect y="18.46" width="60" height="4.62"/><rect y="27.69" width="60" height="4.62"/><rect y="36.92" width="60" height="4.62"/><rect y="46.15" width="60" height="4.62"/><rect y="55.38" width="60" height="4.62"/></g><rect width="27" height="32.3" fill="#3C3B6E"/><g fill="#fff"><circle cx="5" cy="5" r="1.9"/><circle cx="14" cy="5" r="1.9"/><circle cx="23" cy="5" r="1.9"/><circle cx="9.5" cy="12" r="1.9"/><circle cx="18.5" cy="12" r="1.9"/><circle cx="5" cy="19" r="1.9"/><circle cx="14" cy="19" r="1.9"/><circle cx="23" cy="19" r="1.9"/><circle cx="9.5" cy="26" r="1.9"/><circle cx="18.5" cy="26" r="1.9"/></g></g></svg>',
    ro: '<svg viewBox="0 0 60 60" aria-hidden="true" focusable="false"><clipPath id="fc-ro"><circle cx="30" cy="30" r="30"/></clipPath><g clip-path="url(#fc-ro)"><rect width="20" height="60" fill="#002B7F"/><rect x="20" width="20" height="60" fill="#FCD116"/><rect x="40" width="20" height="60" fill="#CE1126"/></g></svg>'
  };

  const languages = [
    { code: 'en', name: 'English' },
    { code: 'ro', name: 'Română' }
  ];

  const menu = document.createElement('div');
  menu.className = 'lang-menu';
  menu.setAttribute('role', 'listbox');
  document.body.appendChild(menu);

  menu.innerHTML = languages.map((language) => `
    <button class="lang-option" type="button" role="option" data-lang-code="${language.code}">
      <span class="lang-flag">${flags[language.code] || ''}</span>
      <span class="lang-name">${language.name}</span>
      <span class="lang-check">✓</span>
    </button>`).join('');

  const closeMenu = () => {
    menu.classList.remove('is-open');
    toggle.setAttribute('aria-expanded', 'false');
  };

  // The notch clips its own overflow, so the menu lives on <body> and is
  // parked under the toggle each time it opens.
  const openMenu = () => {
    const box = toggle.getBoundingClientRect();
    menu.style.top = `${box.bottom + 10}px`;
    menu.style.right = `${Math.max(12, window.innerWidth - box.right - 40)}px`;
    menu.classList.add('is-open');
    toggle.setAttribute('aria-expanded', 'true');
  };

  const applyLanguage = (language) => {
    currentLanguage = translations[language] ? language : defaultLanguage;

    document.querySelectorAll('[data-i18n]').forEach((element) => {
      const value = t(element.dataset.i18n);
      if (value) element.innerHTML = value;
    });
    document.querySelectorAll('[data-i18n-aria]').forEach((element) => {
      const value = t(element.dataset.i18nAria);
      if (value) element.setAttribute('aria-label', value);
    });
    document.querySelectorAll('[data-i18n-alt]').forEach((element) => {
      const value = t(element.dataset.i18nAlt);
      if (value) element.setAttribute('alt', value);
    });

    const pageTitle = t(document.documentElement.dataset.titleKey || 'meta.title');
    if (pageTitle) document.title = pageTitle;
    const description = document.querySelector('meta[name="description"]');
    if (description && t('meta.description')) description.setAttribute('content', t('meta.description'));

    document.documentElement.lang = currentLanguage;
    toggle.innerHTML = `<span class="lang-flag">${flags[currentLanguage] || ''}</span>`;
    menu.querySelectorAll('.lang-option').forEach((option) => {
      const isActive = option.dataset.langCode === currentLanguage;
      option.classList.toggle('is-active', isActive);
      option.setAttribute('aria-selected', String(isActive));
    });
    localStorage.setItem('ipaste-language', currentLanguage);
  };

  const saved = localStorage.getItem('ipaste-language');
  applyLanguage(languages.some((language) => language.code === saved) ? saved : 'en');

  toggle.addEventListener('click', (event) => {
    event.stopPropagation();
    if (menu.classList.contains('is-open')) closeMenu(); else openMenu();
  });

  menu.addEventListener('click', (event) => {
    const option = event.target.closest('.lang-option');
    if (!option) return;
    applyLanguage(option.dataset.langCode);
    closeMenu();
  });

  document.addEventListener('click', (event) => {
    if (!menu.contains(event.target)) closeMenu();
  });
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') closeMenu();
  });
  window.addEventListener('scroll', closeMenu, { passive: true });
})();

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
