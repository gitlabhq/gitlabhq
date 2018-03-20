import mutations from 'ee/ide/stores/mutations/tree';
import state from 'ee/ide/stores/state';
import { file } from '../../helpers';

describe('Multi-file store tree mutations', () => {
  let localState;
  let localTree;

  beforeEach(() => {
    localState = state();
    localTree = file();

    localState.entries[localTree.path] = localTree;
  });

  describe('TOGGLE_TREE_OPEN', () => {
    it('toggles tree open', () => {
      mutations.TOGGLE_TREE_OPEN(localState, localTree.path);

      expect(localTree.opened).toBeTruthy();

      mutations.TOGGLE_TREE_OPEN(localState, localTree.path);

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
      localState.trees['project/master'] = {
        tree: [],
      };

      mutations.SET_DIRECTORY_DATA(localState, {
        data,
        treePath: 'project/master',
      });

      const tree = localState.trees['project/master'];

      expect(tree.tree.length).toBe(3);
      expect(tree.tree[0].name).toBe('tree');
      expect(tree.tree[1].name).toBe('submodule');
      expect(tree.tree[2].name).toBe('blob');
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
