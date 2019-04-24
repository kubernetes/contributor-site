function anchorTags() {
  const selectors = '.doc-content h1, .doc-content h2, .doc-content h3, .doc-content h4';

  anchors.options = {
    icon: '#'
  }

  anchors.add(selectors);
}

function navbarToggle() {
  $('.navbar-burger').click(function() {
    $('.navbar-burger').toggleClass('is-active');
    $(".navbar-menu").toggleClass("is-active");
  });
}

$(function() {
  navbarToggle();
  anchorTags();
});
