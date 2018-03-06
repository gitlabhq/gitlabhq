import mutations from 'ee/ide/stores/mutations/tree';
import state from 'ee/ide/stores/state';
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
    const data = [{
      name: 'tree',
    },
    {
      name: 'submodule',
    },
    {
      name: 'blob',
    }];

    it('adds directory data', () => {
      mutations.SET_DIRECTORY_DATA(localState, {
        data,
        tree: localState,
      });

      expect(localState.tree.length).toBe(3);
      expect(localState.tree[0].name).toBe('tree');
      expect(localState.tree[1].name).toBe('submodule');
      expect(localState.tree[2].name).toBe('blob');
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
      const tmpEntry = file('tmpTree');

      mutations.CREATE_TMP_TREE(localState, {
        tmpEntry,
        parent: localTree,
      });

      expect(localTree.tree.length).toBe(1);
      expect(localTree.tree[0].name).toBe(tmpEntry.name);
    });
  });

  describe('REMOVE_ALL_CHANGES_FILES', () => {
    it('removes all files from changedFiles state', () => {
      localState.changedFiles.push(file('REMOVE_ALL_CHANGES_FILES'));

      mutations.REMOVE_ALL_CHANGES_FILES(localState);

      expect(localState.changedFiles.length).toBe(0);
    });
  });
});
