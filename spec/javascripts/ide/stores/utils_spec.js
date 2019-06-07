import * as utils from '~/ide/stores/utils';
import { commitActionTypes } from '~/ide/constants';
import { file } from '../helpers';

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
      localState = [
        {
          path: '1',
        },
        {
          path: '2',
        },
      ];
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
        tree: [
          {
            type: 'tree',
            name: 'test',
          },
          {
            type: 'blob',
            name: 'file',
          },
        ],
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

  describe('createCommitPayload', () => {
    it('returns API payload', () => {
      const state = {
        commitMessage: 'commit message',
      };
      const rootState = {
        stagedFiles: [
          {
            ...file('staged'),
            path: 'staged',
            content: 'updated file content',
            lastCommitSha: '123456789',
          },
          {
            ...file('newFile'),
            path: 'added',
            tempFile: true,
            content: 'new file content',
            base64: true,
            lastCommitSha: '123456789',
          },
          {
            ...file('deletedFile'),
            path: 'deletedFile',
            deleted: true,
          },
        ],
        currentBranchId: 'master',
      };
      const payload = utils.createCommitPayload({
        branch: 'master',
        newBranch: false,
        state,
        rootState,
        getters: {},
      });

      expect(payload).toEqual({
        branch: 'master',
        commit_message: 'commit message',
        actions: [
          {
            action: commitActionTypes.update,
            file_path: 'staged',
            content: 'updated file content',
            encoding: 'text',
            last_commit_id: '123456789',
            previous_path: undefined,
          },
          {
            action: commitActionTypes.create,
            file_path: 'added',
            content: 'new file content',
            encoding: 'base64',
            last_commit_id: '123456789',
            previous_path: undefined,
          },
          {
            action: commitActionTypes.delete,
            file_path: 'deletedFile',
            content: undefined,
            encoding: 'text',
            last_commit_id: undefined,
            previous_path: undefined,
          },
        ],
        start_branch: undefined,
      });
    });

    it('uses prebuilt commit message when commit message is empty', () => {
      const rootState = {
        stagedFiles: [
          {
            ...file('staged'),
            path: 'staged',
            content: 'updated file content',
            lastCommitSha: '123456789',
          },
          {
            ...file('newFile'),
            path: 'added',
            tempFile: true,
            content: 'new file content',
            base64: true,
            lastCommitSha: '123456789',
          },
        ],
        currentBranchId: 'master',
      };
      const payload = utils.createCommitPayload({
        branch: 'master',
        newBranch: false,
        state: {},
        rootState,
        getters: {
          preBuiltCommitMessage: 'prebuilt test commit message',
        },
      });

      expect(payload).toEqual({
        branch: 'master',
        commit_message: 'prebuilt test commit message',
        actions: [
          {
            action: commitActionTypes.update,
            file_path: 'staged',
            content: 'updated file content',
            encoding: 'text',
            last_commit_id: '123456789',
            previous_path: undefined,
          },
          {
            action: commitActionTypes.create,
            file_path: 'added',
            content: 'new file content',
            encoding: 'base64',
            last_commit_id: '123456789',
            previous_path: undefined,
          },
        ],
        start_branch: undefined,
      });
    });
  });

  describe('commitActionForFile', () => {
    it('returns deleted for deleted file', () => {
      expect(utils.commitActionForFile({ deleted: true })).toBe(commitActionTypes.delete);
    });

    it('returns create for tempFile', () => {
      expect(utils.commitActionForFile({ tempFile: true })).toBe(commitActionTypes.create);
    });

    it('returns move for moved file', () => {
      expect(utils.commitActionForFile({ prevPath: 'test' })).toBe(commitActionTypes.move);
    });

    it('returns update by default', () => {
      expect(utils.commitActionForFile({})).toBe(commitActionTypes.update);
    });
  });

  describe('getCommitFiles', () => {
    it('returns list of files excluding moved files', () => {
      const files = [
        {
          path: 'a',
          type: 'blob',
          deleted: true,
        },
        {
          path: 'c',
          type: 'blob',
          moved: true,
        },
      ];

      const flattendFiles = utils.getCommitFiles(files);

      expect(flattendFiles).toEqual([
        {
          path: 'a',
          type: 'blob',
          deleted: true,
        },
      ]);
    });
  });

  describe('mergeTrees', () => {
    let fromTree;
    let toTree;

    beforeEach(() => {
      fromTree = [file('foo')];
      toTree = [file('bar')];
    });

    it('merges simple trees with sorting the result', () => {
      toTree = [file('beta'), file('alpha'), file('gamma')];
      const res = utils.mergeTrees(fromTree, toTree);

      expect(res.length).toEqual(4);
      expect(res[0].name).toEqual('alpha');
      expect(res[1].name).toEqual('beta');
      expect(res[2].name).toEqual('foo');
      expect(res[3].name).toEqual('gamma');
      expect(res[2]).toBe(fromTree[0]);
    });

    it('handles edge cases', () => {
      expect(utils.mergeTrees({}, []).length).toEqual(0);

      let res = utils.mergeTrees({}, toTree);

      expect(res.length).toEqual(1);
      expect(res[0].name).toEqual('bar');

      res = utils.mergeTrees(fromTree, []);

      expect(res.length).toEqual(1);
      expect(res[0].name).toEqual('foo');
      expect(res[0]).toBe(fromTree[0]);
    });

    it('merges simple trees without producing duplicates', () => {
      toTree.push(file('foo'));

      const res = utils.mergeTrees(fromTree, toTree);

      expect(res.length).toEqual(2);
      expect(res[0].name).toEqual('bar');
      expect(res[1].name).toEqual('foo');
      expect(res[1]).not.toBe(fromTree[0]);
    });

    it('merges nested tree into the main one without duplicates', () => {
      fromTree[0].tree.push({
        ...file('alpha'),
        path: 'foo/alpha',
        tree: [
          {
            ...file('beta.md'),
            path: 'foo/alpha/beta.md',
          },
        ],
      });

      toTree.push({
        ...file('foo'),
        tree: [
          {
            ...file('alpha'),
            path: 'foo/alpha',
            tree: [
              {
                ...file('gamma.md'),
                path: 'foo/alpha/gamma.md',
              },
            ],
          },
        ],
      });

      const res = utils.mergeTrees(fromTree, toTree);

      expect(res.length).toEqual(2);
      expect(res[1].name).toEqual('foo');

      const finalBranch = res[1].tree[0].tree;

      expect(finalBranch.length).toEqual(2);
      expect(finalBranch[0].name).toEqual('beta.md');
      expect(finalBranch[1].name).toEqual('gamma.md');
    });

    it('marks correct folders as opened as the parsing goes on', () => {
      fromTree[0].tree.push({
        ...file('alpha'),
        path: 'foo/alpha',
        tree: [
          {
            ...file('beta.md'),
            path: 'foo/alpha/beta.md',
          },
        ],
      });

      toTree.push({
        ...file('foo'),
        tree: [
          {
            ...file('alpha'),
            path: 'foo/alpha',
            tree: [
              {
                ...file('gamma.md'),
                path: 'foo/alpha/gamma.md',
              },
            ],
          },
        ],
      });

      const res = utils.mergeTrees(fromTree, toTree);

      expect(res[1].name).toEqual('foo');
      expect(res[1].opened).toEqual(true);

      expect(res[1].tree[0].name).toEqual('alpha');
      expect(res[1].tree[0].opened).toEqual(true);
    });
  });
});
