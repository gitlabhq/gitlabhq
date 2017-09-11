import 'jquery';
import 'jquery-ujs';
import '~/ajax_loading_spinner';

describe('Ajax Loading Spinner', () => {
  const fixtureTemplate = 'static/ajax_loading_spinner.html.raw';
  preloadFixtures(fixtureTemplate);

  beforeEach(() => {
    loadFixtures(fixtureTemplate);
    gl.AjaxLoadingSpinner.init();
  });

  it('ajaxBeforeSend', () => {
    const ajaxLoadingSpinner = document.querySelector('.js-ajax-loading-spinner');
    const icon = ajaxLoadingSpinner.querySelector('i');

    $(ajaxLoadingSpinner).trigger('ajax:beforeSend');

    expect(icon).not.toHaveClass('fa-trash-o');
    expect(icon).toHaveClass('fa-spinner');
    expect(icon).toHaveClass('fa-spin');
    expect(icon.dataset.icon).toEqual('fa-trash-o');
    expect(ajaxLoadingSpinner.getAttribute('disabled')).toEqual('');
  });

  it('ajaxComplete', () => {
    const ajaxLoadingSpinner = document.querySelector('.js-ajax-loading-spinner');
    const icon = ajaxLoadingSpinner.querySelector('i');

    $(ajaxLoadingSpinner).trigger('ajax:ajaxComplete');

    expect(icon).toHaveClass('fa-trash-o');
    expect(icon).not.toHaveClass('fa-spinner');
    expect(icon).not.toHaveClass('fa-spin');
    expect(ajaxLoadingSpinner.getAttribute('disabled')).toEqual(null);
  });
});
