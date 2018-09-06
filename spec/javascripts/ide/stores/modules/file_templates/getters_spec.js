import * as getters from '~/ide/stores/modules/file_templates/getters';

describe('IDE file templates getters', () => {
  describe('templateTypes', () => {
    it('returns list of template types', () => {
      expect(getters.templateTypes().length).toBe(4);
    });
  });

  describe('showFileTemplatesBar', () => {
    it('finds template type by name', () => {
      expect(
        getters.showFileTemplatesBar(null, {
          templateTypes: getters.templateTypes(),
        })('LICENSE'),
      ).toEqual({
        name: 'LICENSE',
        key: 'licenses',
      });
    });

    it('returns undefined if not found', () => {
      expect(
        getters.showFileTemplatesBar(null, {
          templateTypes: getters.templateTypes(),
        })('test'),
      ).toBe(undefined);
    });
  });
});
