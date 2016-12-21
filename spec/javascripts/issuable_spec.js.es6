/* global Issuable */
/* global Turbolinks */

//= require issuable
//= require turbolinks

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
    fixture.preload('issuable_filter');

    beforeEach(() => {
      fixture.load('issuable_filter');
      Issuable.init();
    });

    it('should be defined', () => {
      expect(window.Issuable).toBeDefined();
    });

    describe('filtering', () => {
      let $filtersForm;

      beforeEach(() => {
        $filtersForm = $('.js-filter-form');
        fixture.load('issuable_filter');
        resetForm($filtersForm);
      });

      it('should contain only the default parameters', () => {
        spyOn(Turbolinks, 'visit');

        Issuable.filterResults($filtersForm);

        expect(Turbolinks.visit).toHaveBeenCalledWith(BASE_URL + DEFAULT_PARAMS);
      });

      it('should filter for the phrase "broken"', () => {
        spyOn(Turbolinks, 'visit');

        updateForm({ search: 'broken' }, $filtersForm);
        Issuable.filterResults($filtersForm);
        const params = `${DEFAULT_PARAMS}&search=broken`;

        expect(Turbolinks.visit).toHaveBeenCalledWith(BASE_URL + params);
      });

      it('should keep query parameters after modifying filter', () => {
        spyOn(Turbolinks, 'visit');

        // initial filter
        updateForm({ milestone_title: 'v1.0' }, $filtersForm);

        Issuable.filterResults($filtersForm);
        let params = `${DEFAULT_PARAMS}&milestone_title=v1.0`;
        expect(Turbolinks.visit).toHaveBeenCalledWith(BASE_URL + params);

        // update filter
        updateForm({ label_name: 'Frontend' }, $filtersForm);

        Issuable.filterResults($filtersForm);
        params = `${DEFAULT_PARAMS}&milestone_title=v1.0&label_name=Frontend`;
        expect(Turbolinks.visit).toHaveBeenCalledWith(BASE_URL + params);
      });
    });
  });
})();
