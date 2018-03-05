import * as utils from 'ee/ide/stores/utils';
import state from 'ee/ide/stores/state';
import { file } from '../helpers';

describe('Multi-file store utils', () => {
  describe('setPageTitle', () => {
    it('sets the document page title', () => {
      utils.setPageTitle('test');

      expect(document.title).toBe('test');
    });
  });

  describe('treeList', () => {
    let localState;

    beforeEach(() => {
      localState = state();
    });

    it('returns flat tree list', () => {
      localState.trees = [];
      localState.trees['abcproject/mybranch'] = {
        tree: [],
      };
      const baseTree = localState.trees['abcproject/mybranch'].tree;
      baseTree.push(file('1'));
      baseTree[0].tree.push(file('2'));
      baseTree[0].tree[0].tree.push(file('3'));

      const treeList = utils.treeList(localState, 'abcproject/mybranch');

      expect(treeList.length).toBe(3);
      expect(treeList[1].name).toBe(baseTree[0].tree[0].name);
      expect(treeList[2].name).toBe(baseTree[0].tree[0].tree[0].name);
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
