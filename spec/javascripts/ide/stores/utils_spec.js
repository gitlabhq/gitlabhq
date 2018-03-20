import * as utils from 'ee/ide/stores/utils';

describe('Multi-file store utils', () => {
  describe('setPageTitle', () => {
    it('sets the document page title', () => {
      utils.setPageTitle('test');

      expect(document.title).toBe('test');
    });
  });

  describe('findIndexOfFile', () => {
    let localState;

    beforeEach(() => {
      localState = [{
        path: '1',
      }, {
        path: '2',
      }];
    });

    it('finds in the index of an entry by path', () => {
      const index = utils.findIndexOfFile(localState, {
        path: '2',
      });

      expect(index).toBe(1);
    });
  });

  describe('findEntry', () => {
    let localState;

    beforeEach(() => {
      localState = {
        tree: [{
          type: 'tree',
          name: 'test',
        }, {
          type: 'blob',
          name: 'file',
        }],
      };
    });

    it('returns an entry found by name', () => {
      const foundEntry = utils.findEntry(localState.tree, 'tree', 'test');

      expect(foundEntry.type).toBe('tree');
      expect(foundEntry.name).toBe('test');
    });

    it('returns undefined when no entry found', () => {
      const foundEntry = utils.findEntry(localState.tree, 'blob', 'test');

      expect(foundEntry).toBeUndefined();
    });
  });
});
