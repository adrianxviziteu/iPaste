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

const setMobileMenu = (open) => {
  mainNav?.classList.toggle('is-open', open);
  document.body.classList.toggle('mobile-menu-open', open);
  menuToggle?.setAttribute('aria-expanded', String(open));
  if (menuToggle) menuToggle.textContent = open ? 'Close' : 'Menu';
};

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
  '.social-heading > *',
  '.social-card',
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

document.querySelectorAll('.download-link').forEach((link) => {
  [...link.childNodes].forEach((node) => {
    if (node.nodeType !== Node.TEXT_NODE) return;

    if (node.textContent.includes('Descarcă pentru macOS')) {
      node.textContent = 'Download for macOS';
    } else if (node.textContent.includes('Descarcă aplicația')) {
      node.textContent = 'Download the app';
    } else if (node.textContent.includes('Descarcă')) {
      node.textContent = 'Download';
    }
  });
});

const navBar = document.querySelector('.nav-bar');
const languageControl = document.createElement('div');
languageControl.className = 'language-control';
languageControl.innerHTML = '<button class="language-button" type="button" aria-expanded="false" aria-haspopup="true"><span>EN</span><i>⌄</i></button><div class="language-menu" role="menu"><button type="button" data-locale="en" role="menuitem">English <span>EN</span></button><button type="button" data-locale="ro" role="menuitem">Română <span>RO</span></button></div>';
navBar?.insertBefore(languageControl, menuToggle);
const languageButton = languageControl.querySelector('.language-button');
const languageMenu = languageControl.querySelector('.language-menu');

const translations = {
  en: {
    label: 'Language',
    nav: ['The Notch', 'Features', 'FAQ', 'Follow'],
    mobileDownload: 'Download for macOS',
    eyebrow: 'Lives in your MacBook notch',
    heroTitle: 'Your clipboard.<br /><em>Right in the notch.</em>',
    heroCopy: 'iPaste turns the space around your notch into a visual clipboard shelf. Move to the top of your screen, find anything you copied, and paste it back without leaving your work.',
    meta: ['Always one glance away', 'Fully offline and private', 'macOS Sonoma 14+'],
    introTitle: 'The notch,<br />now actually <em>useful.</em>',
    introCopy: 'Move your pointer to the notch and iPaste expands into a focused clipboard shelf above whatever you’re doing. Search, drag, or paste — then it quietly disappears.',
    tags: ['◒ Notch shelf', '⌁ Hover to open', '⌘ Quick search', '↗ Drag anything', '◌ Screenshots', '✦ Collections'],
    panels: [
      ['Your history<br />opens above<br /><em>your current app.</em>', 'The notch shelf expands without switching windows. Find a color from Figma, a link from Safari, a snippet from Terminal, or that screenshot from last week.'],
      ['Open. Find.<br />Drag it out.<br /><em>Keep moving.</em>', 'Text, links, screenshots, images, code, colors, and files stay inside the notch shelf. Drag an item straight into your current app or paste it with one click.']
    ],
    audiencesTitle: 'Built for <em>everything</em><br />you copy.',
    audiencesCopy: 'From design assets and code snippets to customer replies and personal notes, iPaste keeps every useful piece ready to reuse.',
    audienceCards: [
      ['Designers', 'Keep colors, icons, screenshots, SVGs, gradients, references, and assets close at hand.'],
      ['Developers', 'Save code snippets, commands, errors, JSON, API responses, and links automatically.'],
      ['Writers', 'Capture hooks, taglines, drafts, research links, and all the phrases worth keeping.'],
      ['Founders', 'Organize product ideas, investor notes, competitor screenshots, and daily research.'],
      ['Support teams', 'Reuse your best replies, email templates, customer notes, and support screenshots.'],
      ['Personal use', 'Find addresses, recipes, links, quotes, images, and anything you meant to save.']
    ],
    pricingEyebrow: 'Simple by design',
    pricingTitle: 'Free to use.<br /><em>Open to everyone.</em>',
    pricingCopy: 'No subscription. No account. No catch. iPaste is free forever and open source under the MIT license.',
    priceProductSubtitle: 'Built for macOS Sonoma 14 or later',
    priceBadge: 'MIT licensed',
    priceSubtitle: 'Everything you need to keep moving.',
    priceFeaturesLabel: 'Included with iPaste',
    pricePills: ['Free forever', 'Private by default', 'Open source'],
    price: '0',
    source: 'View source on GitHub ↗',
    priceItems: ['Private by default — nothing leaves your Mac', 'Native macOS app, built with SwiftUI', 'Open source — fork it, audit it, ship it', 'Free forever, with no hidden limits'],
    priceFooterNote: 'Made for the notch',
    priceTrust: ['Free forever', 'Private by default', 'Open source'],
    socialEyebrow: 'Stay close to the project',
    socialTitle: 'Follow the build.<br /><em>Share the signal.</em>',
    socialCopy: 'See what’s new, follow the decisions behind iPaste, and help shape the next release.',
    socialXTitle: 'Follow @adriannviziteu',
    socialXCopy: 'Product notes, updates, and the ideas behind iPaste.',
    socialGitHubTitle: 'Explore iPaste on GitHub',
    socialGitHubCopy: 'Read the code, track releases, or contribute to the project.',
    faqTitle: 'Frequently asked<br /><em>questions.</em>',
    faqCopy: 'Everything you need to know about the iPaste notch shelf, privacy, compatibility, and clipboard storage.',
    faq: [
      ['How does the notch shelf work?', 'Move your pointer to the MacBook notch or use the keyboard shortcut. iPaste expands above your current app, then closes when you’re done.'],
      ['Does iPaste upload my copied content?', 'No. Your clipboard history stays on your Mac. iPaste is local-first and private by default.'],
      ['What types of content does iPaste support?', 'Text, links, screenshots, images, code, colors, and files — all organized in a visual history.'],
      ['Can I use iPaste without a notch?', 'Yes. The notch shelf is the signature experience, while a keyboard shortcut keeps iPaste fast on Macs with any display.'],
      ['Which Macs are supported?', 'iPaste is being built for modern Macs running macOS Sonoma 14 or later.'],
      ['Is iPaste a subscription?', 'No. iPaste is free and open source under the MIT license — no payment, no account, no catch.']
    ],
    downloadLabel: 'iPaste / Built for the notch',
    downloadTitle: 'Your clipboard.<br /><em>One glance away.</em>',
    downloadCopy: 'Turn the top of your Mac into the fastest place to find anything you copied.',
    latest: 'macOS Sonoma 14 or later · Latest build',
    footerTitle: 'Your clipboard.<br /><em>Right in the notch.</em>',
    footerCopy: 'iPaste turns the top of your Mac into a private, visual shelf for everything you copy.',
    footerColumns: [['Menu', 'Home', 'The Notch', 'Features', 'FAQ'], ['Navigation', 'Use cases', 'Download', 'Contact'], ['Legal', 'Privacy Policy', 'Terms of Service', 'Support']]
  },
  ro: {
    label: 'Limbă',
    nav: ['Notch-ul', 'Funcții', 'Întrebări frecvente', 'Urmărește'],
    mobileDownload: 'Descarcă pentru macOS',
    eyebrow: 'Trăiește în notch-ul MacBook-ului',
    heroTitle: 'Clipboard-ul tău.<br /><em>Chiar în notch.</em>',
    heroCopy: 'iPaste transformă spațiul din jurul notch-ului într-un raft vizual pentru clipboard. Mută cursorul în partea de sus a ecranului, găsește orice ai copiat și lipește-l fără să-ți întrerupi munca.',
    meta: ['Mereu la o privire distanță', 'Complet offline și privat', 'macOS Sonoma 14+'],
    introTitle: 'Notch-ul,<br />acum cu adevărat <em>util.</em>',
    introCopy: 'Mută cursorul spre notch, iar iPaste se extinde într-un raft concentrat pentru clipboard, deasupra aplicației curente. Caută, trage sau lipește — apoi dispare discret.',
    tags: ['◒ Raft notch', '⌁ Treci pentru a deschide', '⌘ Căutare rapidă', '↗ Trage orice', '◌ Capturi de ecran', '✦ Colecții'],
    panels: [
      ['Istoricul tău<br />se deschide deasupra<br /><em>aplicației curente.</em>', 'Raftul notch se extinde fără să schimbi ferestrele. Găsește o culoare din Figma, un link din Safari, un fragment din Terminal sau captura de săptămâna trecută.'],
      ['Deschide. Găsește.<br />Trage afară.<br /><em>Continuă.</em>', 'Textele, linkurile, capturile, imaginile, codul, culorile și fișierele rămân în raftul notch. Trage un element direct în aplicația curentă sau lipește-l cu un singur click.']
    ],
    audiencesTitle: 'Creat pentru <em>tot ce</em><br />copiezi.',
    audiencesCopy: 'De la materiale de design și fragmente de cod la răspunsuri pentru clienți și notițe personale, iPaste păstrează tot ce îți este util gata de refolosit.',
    audienceCards: [
      ['Designeri', 'Păstrează culori, pictograme, capturi, SVG-uri, degradeuri, referințe și materiale la îndemână.'],
      ['Dezvoltatori', 'Salvează automat fragmente de cod, comenzi, erori, JSON, răspunsuri API și linkuri.'],
      ['Scriitori', 'Adună idei de început, sloganuri, schițe, linkuri de cercetare și toate formulările importante.'],
      ['Fondatori', 'Organizează idei de produs, notițe pentru investitori, capturi de la competitori și cercetarea zilnică.'],
      ['Echipe de suport', 'Refolosește răspunsurile, șabloanele de email, notițele clienților și capturile de suport.'],
      ['Uz personal', 'Găsește adrese, rețete, linkuri, citate, imagini și orice ai vrut să păstrezi.']
    ],
    pricingEyebrow: 'Simplu, din start',
    pricingTitle: 'Gratuit de folosit.<br /><em>Deschis tuturor.</em>',
    pricingCopy: 'Fără abonament. Fără cont. Fără surprize. iPaste este gratuit pentru totdeauna și open source sub licența MIT.',
    priceProductSubtitle: 'Creat pentru macOS Sonoma 14 sau mai nou',
    priceBadge: 'Licență MIT',
    priceSubtitle: 'Tot ce ai nevoie ca să mergi mai departe.',
    priceFeaturesLabel: 'Inclus în iPaste',
    pricePills: ['Gratuit pentru totdeauna', 'Privat implicit', 'Open source'],
    price: '0',
    source: 'Vezi codul pe GitHub ↗',
    priceItems: ['Privat implicit — nimic nu părăsește Mac-ul tău', 'Aplicație macOS nativă, construită cu SwiftUI', 'Open source — copiază, verifică și publică', 'Gratuit pentru totdeauna, fără limite ascunse'],
    priceFooterNote: 'Creat pentru notch',
    priceTrust: ['Gratuit pentru totdeauna', 'Privat implicit', 'Open source'],
    socialEyebrow: 'Rămâi aproape de proiect',
    socialTitle: 'Urmărește evoluția.<br /><em>Fă parte din poveste.</em>',
    socialCopy: 'Vezi noutățile, urmărește deciziile din spatele iPaste și ajută la conturarea următoarei versiuni.',
    socialXTitle: 'Urmărește @adriannviziteu',
    socialXCopy: 'Note de produs, noutăți și ideile din spatele iPaste.',
    socialGitHubTitle: 'Descoperă iPaste pe GitHub',
    socialGitHubCopy: 'Citește codul, urmărește versiunile sau contribuie la proiect.',
    faqTitle: 'Întrebări<br /><em>frecvente.</em>',
    faqCopy: 'Tot ce trebuie să știi despre raftul notch, confidențialitate, compatibilitate și stocarea clipboard-ului.',
    faq: [
      ['Cum funcționează raftul notch?', 'Mută cursorul spre notch-ul MacBook-ului sau folosește scurtătura de tastatură. iPaste se extinde deasupra aplicației curente și se închide când ai terminat.'],
      ['iPaste încarcă ce copiez?', 'Nu. Istoricul clipboard-ului rămâne pe Mac-ul tău. iPaste este local și privat implicit.'],
      ['Ce tipuri de conținut acceptă iPaste?', 'Texte, linkuri, capturi, imagini, cod, culori și fișiere — toate organizate într-un istoric vizual.'],
      ['Pot folosi iPaste fără notch?', 'Da. Raftul notch este experiența principală, iar o scurtătură de tastatură păstrează iPaste rapid pe orice Mac.'],
      ['Ce Mac-uri sunt compatibile?', 'iPaste este construit pentru Mac-uri moderne care rulează macOS Sonoma 14 sau o versiune ulterioară.'],
      ['iPaste este pe bază de abonament?', 'Nu. iPaste este gratuit și open source sub licența MIT — fără plată, cont sau surprize.']
    ],
    downloadLabel: 'iPaste / Creat pentru notch',
    downloadTitle: 'Clipboard-ul tău.<br /><em>La o privire distanță.</em>',
    downloadCopy: 'Transformă partea de sus a Mac-ului în cel mai rapid loc pentru a găsi orice ai copiat.',
    latest: 'macOS Sonoma 14 sau mai nou · Ultima versiune',
    footerTitle: 'Clipboard-ul tău.<br /><em>Chiar în notch.</em>',
    footerCopy: 'iPaste transformă partea de sus a Mac-ului într-un raft vizual și privat pentru tot ce copiezi.',
    footerColumns: [['Meniu', 'Acasă', 'Notch-ul', 'Funcții', 'Întrebări frecvente'], ['Navigare', 'Cazuri de utilizare', 'Descarcă', 'Contact'], ['Legal', 'Politica de confidențialitate', 'Termeni și condiții', 'Suport']]
  }
};

const setHTML = (selector, value) => {
  const element = document.querySelector(selector);
  if (element) element.innerHTML = value;
};

const setText = (selector, value) => {
  const element = document.querySelector(selector);
  if (element) element.textContent = value;
};

const setDirectText = (element, value) => {
  if (!element) return;
  const textNode = [...element.childNodes].find((node) => node.nodeType === Node.TEXT_NODE);
  if (textNode) textNode.textContent = value;
  else element.prepend(document.createTextNode(value));
};

const setLanguage = (locale) => {
  const content = translations[locale] || translations.en;
  document.documentElement.lang = locale;
  localStorage.setItem('ipaste-language', locale);
  if (languageButton) languageButton.querySelector('span').textContent = locale.toUpperCase();
  languageControl.querySelectorAll('[data-locale]').forEach((option) => option.classList.toggle('is-active', option.dataset.locale === locale));
  document.querySelectorAll('.nav-links a').forEach((link, index) => setText(`.nav-links a:nth-child(${index + 1})`, content.nav[index]));
  document.querySelectorAll('.mobile-nav > a:not(.download-link)').forEach((link, index) => setDirectText(link, content.nav[index]));
  document.querySelectorAll('.download-link').forEach((link) => setDirectText(link, link.closest('.mobile-nav') ? content.mobileDownload : (locale === 'ro' ? 'Descarcă pentru macOS' : 'Download for macOS')));
  setDirectText(document.querySelector('.hero-eyebrow'), content.eyebrow);
  setHTML('.hero h1', content.heroTitle);
  setText('.hero-content > p', content.heroCopy);
  document.querySelectorAll('.hero-meta span').forEach((element, index) => setText(`.hero-meta span:nth-child(${index + 1})`, content.meta[index]));
  setHTML('.intro h2', content.introTitle);
  setText('.intro > p', content.introCopy);
  document.querySelectorAll('.feature-tags span').forEach((element, index) => setText(`.feature-tags span:nth-child(${index + 1})`, content.tags[index]));
  document.querySelectorAll('.feature-panel .panel-copy').forEach((panel, index) => { panel.querySelector('h2').innerHTML = content.panels[index][0]; panel.querySelector('p').textContent = content.panels[index][1]; });
  setHTML('.audiences h2', content.audiencesTitle);
  setText('.audiences > p', content.audiencesCopy);
  document.querySelectorAll('.audience-grid article').forEach((article, index) => { setText(`.audience-grid article:nth-child(${index + 1}) h3`, content.audienceCards[index][0]); setText(`.audience-grid article:nth-child(${index + 1}) p`, content.audienceCards[index][1]); });
  setText('.pricing-eyebrow', content.pricingEyebrow);
  setHTML('.pricing-intro h2', content.pricingTitle);
  setText('.pricing-intro > p:last-child', content.pricingCopy);
  setText('.price-product > div > span', content.priceProductSubtitle);
  setText('.price-badge', content.priceBadge);
  setText('.price-subtitle', content.priceSubtitle);
  setText('.price-features-label', content.priceFeaturesLabel);
  document.querySelectorAll('.price-trust > span').forEach((element, index) => setText(`.price-trust > span:nth-of-type(${index + 1})`, content.pricePills[index]));
  setText('.price-amount strong', content.price);
  setText('.price-card-footer a', content.source);
  setText('.price-card-footer > span', content.priceFooterNote);
  document.querySelectorAll('.price-features li > span:last-child').forEach((element, index) => setText(`.price-features li:nth-child(${index + 1}) > span:last-child`, content.priceItems[index]));
  setText('.social-eyebrow', content.socialEyebrow);
  setHTML('.social-section h2', content.socialTitle);
  setText('.social-copy', content.socialCopy);
  setText('.social-card-x strong', content.socialXTitle);
  setText('.social-card-x .social-card-copy', content.socialXCopy);
  setText('.social-card-github strong', content.socialGitHubTitle);
  setText('.social-card-github .social-card-copy', content.socialGitHubCopy);
  setHTML('.faq h2', content.faqTitle);
  setText('.faq > p', content.faqCopy);
  document.querySelectorAll('.faq-grid details').forEach((detail, index) => { setDirectText(detail.querySelector('summary'), content.faq[index][0]); setText(`.faq-grid details:nth-child(${index + 1}) p`, content.faq[index][1]); });
  setText('.download-label', content.downloadLabel);
  setHTML('.download-inner h2', content.downloadTitle);
  setText('.download-inner p', content.downloadCopy);
  setText('.download-inner > small', content.latest);
  setHTML('.footer-product h2', content.footerTitle);
  setText('.footer-product > p', content.footerCopy);
  setDirectText(document.querySelector('.footer-button'), locale === 'ro' ? 'Descarcă aplicația' : 'Download the app');
  document.querySelectorAll('.footer-column').forEach((column, columnIndex) => { const values = content.footerColumns[columnIndex]; column.querySelector('strong').textContent = values[0]; column.querySelectorAll('a').forEach((link, linkIndex) => { link.textContent = values[linkIndex + 1]; }); });
};

const initialLanguage = localStorage.getItem('ipaste-language') || 'en';
setLanguage(initialLanguage);
languageButton?.addEventListener('click', () => {
  const isOpen = languageControl.classList.toggle('is-open');
  languageButton.setAttribute('aria-expanded', String(isOpen));
});
languageMenu?.addEventListener('click', (event) => {
  const option = event.target.closest('[data-locale]');
  if (!option) return;
  setLanguage(option.dataset.locale);
  languageControl.classList.remove('is-open');
  languageButton.setAttribute('aria-expanded', 'false');
});
document.addEventListener('click', (event) => {
  if (languageControl.contains(event.target)) return;
  languageControl.classList.remove('is-open');
  languageButton?.setAttribute('aria-expanded', 'false');
});
