import * as getters from '~/ide/stores/getters';
import state from '~/ide/stores/state';
import { file } from '../helpers';

describe('IDE store getters', () => {
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('activeFile', () => {
    it('returns the current active file', () => {
      localState.openFiles.push(file());
      localState.openFiles.push(file('active'));
      localState.openFiles[1].active = true;

      expect(getters.activeFile(localState).name).toBe('active');
    });

    it('returns undefined if no active files are found', () => {
      localState.openFiles.push(file());
      localState.openFiles.push(file('active'));

      expect(getters.activeFile(localState)).toBeNull();
    });
  });

  describe('modifiedFiles', () => {
    it('returns a list of modified files', () => {
      localState.openFiles.push(file());
      localState.changedFiles.push(file('changed'));
      localState.changedFiles[0].changed = true;

      const modifiedFiles = getters.modifiedFiles(localState);

      expect(modifiedFiles.length).toBe(1);
      expect(modifiedFiles[0].name).toBe('changed');
    });
  });

  describe('currentMergeRequest', () => {
    it('returns Current Merge Request', () => {
      localState.currentProjectId = 'abcproject';
      localState.currentMergeRequestId = 1;
      localState.projects.abcproject = {
        mergeRequests: {
          1: { mergeId: 1 },
        },
      };

      expect(getters.currentMergeRequest(localState).mergeId).toBe(1);
    });

    it('returns null if no active Merge Request was found', () => {
      localState.currentProjectId = 'otherproject';

      expect(getters.currentMergeRequest(localState)).toBeNull();
    });
  });

  describe('allBlobs', () => {
    beforeEach(() => {
      Object.assign(localState.entries, {
        index: { type: 'blob', name: 'index', lastOpenedAt: 0 },
        app: { type: 'blob', name: 'blob', lastOpenedAt: 0 },
        folder: { type: 'folder', name: 'folder', lastOpenedAt: 0 },
      });
    });

    it('returns only blobs', () => {
      expect(getters.allBlobs(localState).length).toBe(2);
    });

    it('returns list sorted by lastOpenedAt', () => {
      localState.entries.app.lastOpenedAt = new Date().getTime();

      expect(getters.allBlobs(localState)[0].name).toBe('blob');
    });
  });

  describe('getChangesInFolder', () => {
    it('returns length of changed files for a path', () => {
      localState.changedFiles.push(
        {
          path: 'test/index',
          name: 'index',
        },
        {
          path: 'app/123',
          name: '123',
        },
      );

      expect(getters.getChangesInFolder(localState)('test')).toBe(1);
    });

    it('returns length of changed & staged files for a path', () => {
      localState.changedFiles.push(
        {
          path: 'test/index',
          name: 'index',
        },
        {
          path: 'testing/123',
          name: '123',
        },
      );

      localState.stagedFiles.push(
        {
          path: 'test/123',
          name: '123',
        },
        {
          path: 'test/index',
          name: 'index',
        },
        {
          path: 'testing/12345',
          name: '12345',
        },
      );

      expect(getters.getChangesInFolder(localState)('test')).toBe(2);
    });

    it('returns length of changed & tempFiles files for a path', () => {
      localState.changedFiles.push(
        {
          path: 'test/index',
          name: 'index',
        },
        {
          path: 'test/newfile',
          name: 'newfile',
          tempFile: true,
        },
      );

      expect(getters.getChangesInFolder(localState)('test')).toBe(2);
    });
  });

  describe('lastCommit', () => {
    it('returns the last commit of the current branch on the current project', () => {
      const commitTitle = 'Example commit title';
      const localGetters = {
        currentProject: {
          name: 'test-project',
        },
        currentBranch: {
          commit: {
            title: commitTitle,
          },
        },
      };
      localState.currentBranchId = 'example-branch';

      expect(getters.lastCommit(localState, localGetters).title).toBe(commitTitle);
    });
  });

  describe('currentBranch', () => {
    it('returns current projects branch', () => {
      const localGetters = {
        currentProject: {
          branches: {
            master: {
              name: 'master',
            },
          },
        },
      };
      localState.currentBranchId = 'master';

      expect(getters.currentBranch(localState, localGetters)).toEqual({
        name: 'master',
      });
    });
  });

  describe('packageJson', () => {
    it('returns package.json entry', () => {
      localState.entries['package.json'] = { name: 'package.json' };

      expect(getters.packageJson(localState)).toEqual({
        name: 'package.json',
      });
    });
  });

  describe('parsedGitattributes', () => {
    describe('without .gitattributes file', () => {
      it('returns empty object', () => {
        expect(getters.parsedGitattributes(localState)).toEqual({});
      });
    });

    describe('with .gitattributes file', () => {
      beforeEach(() => {
        localState.entries['.gitattributes'] = {
          raw: '',
          content: '',
        };
      });

      it('returns empty object when raw is empty', () => {
        expect(getters.parsedGitattributes(localState)).toEqual({});
      });

      ['raw', 'content'].forEach(key => {
        describe(`${key} key in file object`, () => {
          beforeEach(() => {
            const content =
              '*.png -text\n*.svg binary\nDockerfile text\n*.vue      text\nREADME.md testing';

            if (key === 'content') {
              localState.entries['.gitattributes'].raw = content;
            }

            localState.entries['.gitattributes'][key] = content;
          });

          it('returns parsed .gitattributes', () => {
            expect(getters.parsedGitattributes(localState)).toEqual({
              '*.png': {
                encoding: 'binary',
              },
              '*.svg': {
                encoding: 'binary',
              },
              '*.vue': {
                encoding: 'text',
              },
              Dockerfile: {
                encoding: 'text',
              },
            });
          });

          it('does not include key when encoding is not recognised', () => {
            expect(getters.parsedGitattributes(localState)).not.toEqual(
              jasmine.objectContaining({
                'README.md': {},
              }),
            );
          });
        });
      });
    });
  });

  describe('isFileBinary', () => {
    let localGetters;

    beforeEach(() => {
      localState.entries['.gitattributes'] = {
        raw: '*.svg binary\n*.vue text',
      };

      localGetters = {
        parsedGitattributes: getters.parsedGitattributes(localState),
      };
    });

    it('returns true when gitattributes has binary path', () => {
      expect(
        getters.isFileBinary(localState, localGetters)({
          name: 'test.svg',
        }),
      ).toBe(true);
    });

    it('returns false when gitattributes has text path', () => {
      expect(
        getters.isFileBinary(localState, localGetters)({
          name: 'test.vue',
          binary: false,
        }),
      ).toBe(false);
    });

    it('uses binary key if parsed gittatributes returns false', () => {
      expect(
        getters.isFileBinary(localState, localGetters)({
          name: 'test.vue',
          binary: true,
        }),
      ).toBe(true);
    });
  });
});
