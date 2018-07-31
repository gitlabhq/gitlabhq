import * as utils from '~/ide/stores/utils';
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
            action: 'update',
            file_path: 'staged',
            content: 'updated file content',
            encoding: 'text',
            last_commit_id: '123456789',
            previous_path: undefined,
          },
          {
            action: 'create',
            file_path: 'added',
            content: 'new file content',
            encoding: 'base64',
            last_commit_id: '123456789',
            previous_path: undefined,
          },
          {
            action: 'delete',
            file_path: 'deletedFile',
            content: '',
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
            action: 'update',
            file_path: 'staged',
            content: 'updated file content',
            encoding: 'text',
            last_commit_id: '123456789',
            previous_path: undefined,
          },
          {
            action: 'create',
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
      expect(utils.commitActionForFile({ deleted: true })).toBe('delete');
    });

    it('returns create for tempFile', () => {
      expect(utils.commitActionForFile({ tempFile: true })).toBe('create');
    });

    it('returns move for moved file', () => {
      expect(utils.commitActionForFile({ prevPath: 'test' })).toBe('move');
    });

    it('returns update by default', () => {
      expect(utils.commitActionForFile({})).toBe('update');
    });
  });

  describe('getCommitFiles', () => {
    it('returns flattened list of files and folders', () => {
      const files = [
        {
          path: 'a',
          type: 'blob',
          deleted: true,
        },
        {
          path: 'b',
          type: 'tree',
          deleted: true,
          tree: [
            {
              path: 'c',
              type: 'blob',
            },
            {
              path: 'd',
              type: 'blob',
            },
          ],
        },
        {
          path: 'c',
          prevPath: 'x',
          type: 'tree',
          tree: [
            {
              path: 'c/index.js',
              type: 'blob',
            },
          ],
        },
      ];

      const flattendFiles = utils.getCommitFiles(files);

      expect(flattendFiles).toEqual([
        {
          path: 'a',
          type: 'blob',
          deleted: true,
        },
        {
          path: 'c',
          type: 'blob',
          deleted: true,
        },
        {
          path: 'd',
          type: 'blob',
          deleted: true,
        },
        {
          path: 'c/index.js',
          type: 'blob',
          deleted: true,
        },
      ]);
    });
  });
});
