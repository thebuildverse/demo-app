// Smooth reveal on scroll
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
      }
    });
  },
  { threshold: 0.1 }
);

document.querySelectorAll('.card, .secret-card, .arch-diagram').forEach((el) => {
  el.style.opacity = '0';
  el.style.transform = 'translateY(20px)';
  el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
  observer.observe(el);
});

document.addEventListener('DOMContentLoaded', () => {
  // Add visible class handler
  const style = document.createElement('style');
  style.textContent = '.visible { opacity: 1 !important; transform: translateY(0) !important; }';
  document.head.appendChild(style);

  // Check if secret message placeholder was replaced
  const secretEl = document.getElementById('secret-message');
  if (secretEl && secretEl.textContent === '{{SECRET_MESSAGE}}') {
    secretEl.textContent = '⚠️ Secret not injected — see README for External Secrets setup';
    secretEl.style.color = '#fbbf24';
  }
});
