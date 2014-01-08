$(document).foundation();

$('a.left-off-canvas-toggle').click(function() {
  $('.inner-wrap').css('min-height', $(window).height() - $('footer').outerHeight() + 'px');
});
