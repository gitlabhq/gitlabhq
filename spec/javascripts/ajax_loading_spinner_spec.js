import $ from 'jquery';
import AjaxLoadingSpinner from '~/ajax_loading_spinner';

describe('Ajax Loading Spinner', () => {
  const fixtureTemplate = 'static/ajax_loading_spinner.html.raw';
  preloadFixtures(fixtureTemplate);

  beforeEach(() => {
    loadFixtures(fixtureTemplate);
    AjaxLoadingSpinner.init();
  });

  it('change current icon with spinner icon and disable link while waiting ajax response', (done) => {
    spyOn($, 'ajax').and.callFake((req) => {
      const xhr = new XMLHttpRequest();
      const ajaxLoadingSpinner = document.querySelector('.js-ajax-loading-spinner');
      const icon = ajaxLoadingSpinner.querySelector('i');

      req.beforeSend(xhr, { dataType: 'text/html' });

      expect(icon).not.toHaveClass('fa-trash-o');
      expect(icon).toHaveClass('fa-spinner');
      expect(icon).toHaveClass('fa-spin');
      expect(icon.dataset.icon).toEqual('fa-trash-o');
      expect(ajaxLoadingSpinner.getAttribute('disabled')).toEqual('');

      req.complete({});

      done();
      const deferred = $.Deferred();
      return deferred.promise();
    });
    document.querySelector('.js-ajax-loading-spinner').click();
  });

  it('use original icon again and enabled the link after complete the ajax request', (done) => {
    spyOn($, 'ajax').and.callFake((req) => {
      const xhr = new XMLHttpRequest();
      const ajaxLoadingSpinner = document.querySelector('.js-ajax-loading-spinner');

      req.beforeSend(xhr, { dataType: 'text/html' });
      req.complete({});

      const icon = ajaxLoadingSpinner.querySelector('i');
      expect(icon).toHaveClass('fa-trash-o');
      expect(icon).not.toHaveClass('fa-spinner');
      expect(icon).not.toHaveClass('fa-spin');
      expect(ajaxLoadingSpinner.getAttribute('disabled')).toEqual(null);

      done();
      const deferred = $.Deferred();
      return deferred.promise();
    });
    document.querySelector('.js-ajax-loading-spinner').click();
  });
});
