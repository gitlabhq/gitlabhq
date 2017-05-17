$(document).on('click', '.js-lineprof-file', function(e) {
  $(this).parents('.heading').next('div').toggle();
  e.preventDefault();
  return false;
});
