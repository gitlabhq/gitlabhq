//= require gfm_auto_complete
//= require jquery
//= require jquery.atwho

const global = window.gl || (window.gl = {});
const GfmAutoComplete = global.GfmAutoComplete;

describe('GfmAutoComplete', function () {
  describe('DefaultOptions.sorter', function () {
    describe('assets loading', function () {
      beforeEach(function () {
        spyOn(GfmAutoComplete, 'isLoading').and.returnValue(true);

        this.atwhoInstance = { setting: {} };
        this.items = [];

        this.sorterValue = GfmAutoComplete.DefaultOptions.sorter
          .call(this.atwhoInstance, '', this.items);
      });

      it('should disable highlightFirst', function () {
        expect(this.atwhoInstance.setting.highlightFirst).toBe(false);
      });

      it('should return the passed unfiltered items', function () {
        expect(this.sorterValue).toEqual(this.items);
      });
    });

    describe('assets finished loading', function () {
      beforeEach(function () {
        spyOn(GfmAutoComplete, 'isLoading').and.returnValue(false);
        spyOn($.fn.atwho.default.callbacks, 'sorter');
      });

      it('should enable highlightFirst if alwaysHighlightFirst is set', function () {
        const atwhoInstance = { setting: { alwaysHighlightFirst: true } };

        GfmAutoComplete.DefaultOptions.sorter.call(atwhoInstance);

        expect(atwhoInstance.setting.highlightFirst).toBe(true);
      });

      it('should enable highlightFirst if a query is present', function () {
        const atwhoInstance = { setting: {} };

        GfmAutoComplete.DefaultOptions.sorter.call(atwhoInstance, 'query');

        expect(atwhoInstance.setting.highlightFirst).toBe(true);
      });

      it('should call the default atwho sorter', function () {
        const atwhoInstance = { setting: {} };

        const query = 'query';
        const items = [];
        const searchKey = 'searchKey';

        GfmAutoComplete.DefaultOptions.sorter.call(atwhoInstance, query, items, searchKey);

        expect($.fn.atwho.default.callbacks.sorter).toHaveBeenCalledWith(query, items, searchKey);
      });
    });
  });
});
