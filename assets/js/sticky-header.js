document.addEventListener('DOMContentLoaded', () => {
  const navbar = document.querySelector('.td-navbar');
  if (!navbar) return;
  const handleScroll = () => {
    navbar.classList.toggle('scrolled', window.scrollY > 10);
  };
  window.addEventListener('scroll', handleScroll);
  handleScroll();
});
