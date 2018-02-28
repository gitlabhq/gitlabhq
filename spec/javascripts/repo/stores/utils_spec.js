import * as utils from '~/repo/stores/utils';

describe('Multi-file store utils', () => {
  describe('setPageTitle', () => {
    it('sets the document page title', () => {
      utils.setPageTitle('test');

      expect(document.title).toBe('test');
    });
  });

  describe('pushState', () => {
    it('calls history.pushState', () => {
      spyOn(history, 'pushState');

      utils.pushState('test');

      expect(history.pushState).toHaveBeenCalledWith({ url: 'test' }, '', 'test');
    });
  });

  describe('createTemp', () => {
    it('creates temp tree', () => {
      const tmp = utils.createTemp({
        name: 'test',
        path: 'test',
        type: 'tree',
        level: 0,
        changed: false,
        content: '',
        base64: '',
      });

      expect(tmp.tempFile).toBeTruthy();
      expect(tmp.icon).toBe('fa-folder');
    });

    it('creates temp file', () => {
      const tmp = utils.createTemp({
        name: 'test',
        path: 'test',
        type: 'blob',
        level: 0,
        changed: false,
        content: '',
        base64: '',
      });

      expect(tmp.tempFile).toBeTruthy();
      expect(tmp.icon).toBe('fa-file-text-o');
    });
  });

  describe('findIndexOfFile', () => {
    let state;

    beforeEach(() => {
      state = [{
        path: '1',
      }, {
        path: '2',
      }];
    });

    it('finds in the index of an entry by path', () => {
      const index = utils.findIndexOfFile(state, {
        path: '2',
      });

      expect(index).toBe(1);
    });
  });

  describe('findEntry', () => {
    let state;

    beforeEach(() => {
      state = {
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
      const foundEntry = utils.findEntry(state, 'tree', 'test');

      expect(foundEntry.type).toBe('tree');
      expect(foundEntry.name).toBe('test');
    });

    it('returns undefined when no entry found', () => {
      const foundEntry = utils.findEntry(state, 'blob', 'test');

      expect(foundEntry).toBeUndefined();
    });
  });
});
