import { getDecoratedId, parseDecoratedId } from '~/project_select_multi';

describe('project_select_multi', () => {
  const TEST_PROJ = {
    id: '6',
  };

  describe('parseDecoratedId', () => {
    it('can parse an unselected id', () => {
      const id = getDecoratedId(TEST_PROJ, false);

      const result = parseDecoratedId(id);

      expect(result).toEqual({
        id: TEST_PROJ.id,
        isSelected: false,
      });
    });

    it('can parse a selected id', () => {
      const id = getDecoratedId(TEST_PROJ, true);

      const result = parseDecoratedId(id);

      expect(result).toEqual({
        id: TEST_PROJ.id,
        isSelected: true,
      });
    });
  });
});
