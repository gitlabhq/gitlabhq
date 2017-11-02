import mutations from '~/repo/stores/mutations/tree';
import state from '~/repo/stores/state';
import { file } from '../../helpers';

describe('Multi-file store tree mutations', () => {
  let localState;
  let localTree;

  beforeEach(() => {
    localState = state();
    localTree = file();
  });

  describe('TOGGLE_TREE_OPEN', () => {
    it('toggles tree open', () => {
      mutations.TOGGLE_TREE_OPEN(localState, localTree);

      expect(localTree.opened).toBeTruthy();

      mutations.TOGGLE_TREE_OPEN(localState, localTree);

      expect(localTree.opened).toBeFalsy();
    });
  });

  describe('SET_DIRECTORY_DATA', () => {
    const data = {
      trees: [{
        name: 'tree',
      }],
      submodules: [{
        name: 'submodule',
      }],
      blobs: [{
        name: 'blob',
      }],
    };

    it('adds directory data', () => {
      mutations.SET_DIRECTORY_DATA(localState, {
        data,
        tree: localState,
      });

      expect(localState.tree.length).toBe(3);
      expect(localState.tree[0].type).toBe('tree');
      expect(localState.tree[1].type).toBe('submodule');
      expect(localState.tree[2].type).toBe('blob');
    });

    it('defaults to rootUrl when no parent_tree_url is in data', () => {
      localState.endpoints.rootUrl = 'test';

      mutations.SET_DIRECTORY_DATA(localState, {
        data,
        tree: localState,
      });

      expect(localState.tree[0].parentTreeUrl).toBe('test');
    });

    it('uses parent_tree_url from data', () => {
      mutations.SET_DIRECTORY_DATA(localState, {
        data: {
          ...data,
          parent_tree_url: 'parent/',
          path: 'test',
        },
        tree: localState,
      });

      expect(localState.tree[0].parentTreeUrl).toBe('parent/test');
    });
  });

  describe('SET_PARENT_TREE_URL', () => {
    it('sets the parent tree url', () => {
      mutations.SET_PARENT_TREE_URL(localState, 'test');

      expect(localState.parentTreeUrl).toBe('test');
    });
  });

  describe('CREATE_TMP_TREE', () => {
    it('adds tree into parent tree', () => {
      const tmpEntry = file();

      mutations.CREATE_TMP_TREE(localState, {
        tmpEntry,
        parent: localTree,
      });

      expect(localTree.tree.length).toBe(1);
      expect(localTree.tree[0].name).toBe(tmpEntry.name);
    });
  });
});
