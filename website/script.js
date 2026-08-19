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

const modal = document.querySelector('.modal');
const notifyButtons = document.querySelectorAll('.notify-button');
const closeModal = document.querySelector('.modal-close');
const emailInput = document.querySelector('#email');

const openModal = (event) => {
  event?.preventDefault();
  modal.classList.add('is-open');
  modal.setAttribute('aria-hidden', 'false');
  window.setTimeout(() => emailInput?.focus(), 100);
};

const hideModal = () => {
  modal.classList.remove('is-open');
  modal.setAttribute('aria-hidden', 'true');
};

notifyButtons.forEach((button) => button.addEventListener('click', openModal));
closeModal?.addEventListener('click', hideModal);
modal?.addEventListener('click', (event) => {
  if (event.target === modal) hideModal();
});
document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') {
    hideModal();
    setMobileMenu(false);
    setNotchShelf(false, false);
  }
});

document.querySelector('.notify-form')?.addEventListener('submit', (event) => {
  event.preventDefault();
  event.currentTarget.hidden = true;
  document.querySelector('.form-success').hidden = false;
});
