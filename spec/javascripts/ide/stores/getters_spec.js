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

    it('returns angle left when collapsed', () => {
      localState.rightPanelCollapsed = true;

      expect(getters.collapseButtonIcon(localState)).toBe('angle-double-left');
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
});
