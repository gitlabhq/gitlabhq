/* global IssuableIndex */

import '~/lib/utils/url_utility';
import '~/issuable_index';

(() => {
  const BASE_URL = '/user/project/issues?scope=all&state=closed';
  const DEFAULT_PARAMS = '&utf8=%E2%9C%93';

  function updateForm(formValues, form) {
    $.each(formValues, (id, value) => {
      $(`#${id}`, form).val(value);
    });
  }

  function resetForm(form) {
    $('input[name!="utf8"]', form).each((index, input) => {
      input.setAttribute('value', '');
    });
  }

  describe('Issuable', () => {
    preloadFixtures('static/issuable_filter.html.raw');

    beforeEach(() => {
      loadFixtures('static/issuable_filter.html.raw');
      IssuableIndex.init();
    });

    it('should be defined', () => {
      expect(window.IssuableIndex).toBeDefined();
    });

    describe('filtering', () => {
      let $filtersForm;

      beforeEach(() => {
        $filtersForm = $('.js-filter-form');
        loadFixtures('static/issuable_filter.html.raw');
        resetForm($filtersForm);
      });

      it('should contain only the default parameters', () => {
        spyOn(gl.utils, 'visitUrl');

        IssuableIndex.filterResults($filtersForm);

        expect(gl.utils.visitUrl).toHaveBeenCalledWith(BASE_URL + DEFAULT_PARAMS);
      });

      it('should filter for the phrase "broken"', () => {
        spyOn(gl.utils, 'visitUrl');

        updateForm({ search: 'broken' }, $filtersForm);
        IssuableIndex.filterResults($filtersForm);
        const params = `${DEFAULT_PARAMS}&search=broken`;

        expect(gl.utils.visitUrl).toHaveBeenCalledWith(BASE_URL + params);
      });

      it('should keep query parameters after modifying filter', () => {
        spyOn(gl.utils, 'visitUrl');

        // initial filter
        updateForm({ milestone_title: 'v1.0' }, $filtersForm);

        IssuableIndex.filterResults($filtersForm);
        let params = `${DEFAULT_PARAMS}&milestone_title=v1.0`;
        expect(gl.utils.visitUrl).toHaveBeenCalledWith(BASE_URL + params);

        // update filter
        updateForm({ label_name: 'Frontend' }, $filtersForm);

        IssuableIndex.filterResults($filtersForm);
        params = `${DEFAULT_PARAMS}&milestone_title=v1.0&label_name=Frontend`;
        expect(gl.utils.visitUrl).toHaveBeenCalledWith(BASE_URL + params);
      });
    });
  });
})();
