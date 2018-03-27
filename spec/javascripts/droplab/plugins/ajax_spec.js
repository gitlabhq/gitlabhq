import AjaxCache from '~/lib/utils/ajax_cache';
import Ajax from '~/droplab/plugins/ajax';

describe('Ajax', () => {
  describe('preprocessing', () => {
    const config = {};

    describe('is not configured', () => {
      it('passes the data through', () => {
        const data = ['data'];
        expect(Ajax.preprocessing(config, data)).toEqual(data);
      });
    });

    describe('is configured', () => {
      const processedArray = ['processed'];

      beforeEach(() => {
        config.preprocessing = () => processedArray;
        spyOn(config, 'preprocessing').and.callFake(() => processedArray);
      });

      it('calls preprocessing', () => {
        Ajax.preprocessing(config, []);
        expect(config.preprocessing.calls.count()).toBe(1);
      });

      it('overrides AjaxCache', () => {
        spyOn(AjaxCache, 'override').and.callFake((endpoint, results) => expect(results).toEqual(processedArray));

        Ajax.preprocessing(config, []);
        expect(AjaxCache.override.calls.count()).toBe(1);
      });
    });
  });
});
