import mutations from '~/ide/stores/mutations';
import state from '~/ide/stores/state';
import { file } from '../helpers';

describe('Multi-file store mutations', () => {
  let localState;
  let entry;

  beforeEach(() => {
    localState = state();
    entry = file();

    localState.entries[entry.path] = entry;
  });

  describe('SET_INITIAL_DATA', () => {
    it('sets all initial data', () => {
      mutations.SET_INITIAL_DATA(localState, {
        test: 'test',
      });

      expect(localState.test).toBe('test');
    });
  });

  describe('TOGGLE_LOADING', () => {
    it('toggles loading of entry', () => {
      mutations.TOGGLE_LOADING(localState, { entry });

      expect(entry.loading).toBeTruthy();

      mutations.TOGGLE_LOADING(localState, { entry });

      expect(entry.loading).toBeFalsy();
    });

    it('toggles loading of entry and sets specific value', () => {
      mutations.TOGGLE_LOADING(localState, { entry });

      expect(entry.loading).toBeTruthy();

      mutations.TOGGLE_LOADING(localState, { entry, forceValue: true });

      expect(entry.loading).toBeTruthy();
    });
  });

  describe('SET_LEFT_PANEL_COLLAPSED', () => {
    it('sets left panel collapsed', () => {
      mutations.SET_LEFT_PANEL_COLLAPSED(localState, true);

      expect(localState.leftPanelCollapsed).toBeTruthy();

      mutations.SET_LEFT_PANEL_COLLAPSED(localState, false);

      expect(localState.leftPanelCollapsed).toBeFalsy();
    });
  });

  describe('SET_RIGHT_PANEL_COLLAPSED', () => {
    it('sets right panel collapsed', () => {
      mutations.SET_RIGHT_PANEL_COLLAPSED(localState, true);

      expect(localState.rightPanelCollapsed).toBeTruthy();

      mutations.SET_RIGHT_PANEL_COLLAPSED(localState, false);

      expect(localState.rightPanelCollapsed).toBeFalsy();
    });
  });

  describe('CLEAR_STAGED_CHANGES', () => {
    it('clears stagedFiles array', () => {
      localState.stagedFiles.push('a');

      mutations.CLEAR_STAGED_CHANGES(localState);

      expect(localState.stagedFiles.length).toBe(0);
    });
  });

  describe('UPDATE_VIEWER', () => {
    it('sets viewer state', () => {
      mutations.UPDATE_VIEWER(localState, 'diff');

      expect(localState.viewer).toBe('diff');
    });
  });

  describe('UPDATE_ACTIVITY_BAR_VIEW', () => {
    it('updates currentActivityBar', () => {
      mutations.UPDATE_ACTIVITY_BAR_VIEW(localState, 'test');

      expect(localState.currentActivityView).toBe('test');
    });
  });

  describe('SET_EMPTY_STATE_SVGS', () => {
    it('updates empty state SVGs', () => {
      mutations.SET_EMPTY_STATE_SVGS(localState, {
        emptyStateSvgPath: 'emptyState',
        noChangesStateSvgPath: 'noChanges',
        committedStateSvgPath: 'commited',
      });

      expect(localState.emptyStateSvgPath).toBe('emptyState');
      expect(localState.noChangesStateSvgPath).toBe('noChanges');
      expect(localState.committedStateSvgPath).toBe('commited');
    });
  });

  describe('UPDATE_TEMP_FLAG', () => {
    beforeEach(() => {
      localState.entries.test = {
        ...file(),
        tempFile: true,
        changed: true,
      };
    });

    it('updates tempFile flag', () => {
      mutations.UPDATE_TEMP_FLAG(localState, { path: 'test', tempFile: false });

      expect(localState.entries.test.tempFile).toBe(false);
    });

    it('updates changed flag', () => {
      mutations.UPDATE_TEMP_FLAG(localState, { path: 'test', tempFile: false });

      expect(localState.entries.test.changed).toBe(false);
    });
  });

  describe('TOGGLE_FILE_FINDER', () => {
    it('updates fileFindVisible', () => {
      mutations.TOGGLE_FILE_FINDER(localState, true);

      expect(localState.fileFindVisible).toBe(true);
    });
  });

  describe('BURST_UNUSED_SEAL', () => {
    it('updates unusedSeal', () => {
      expect(localState.unusedSeal).toBe(true);

      mutations.BURST_UNUSED_SEAL(localState);

      expect(localState.unusedSeal).toBe(false);
    });
  });

  describe('SET_ERROR_MESSAGE', () => {
    it('updates error message', () => {
      mutations.SET_ERROR_MESSAGE(localState, 'error');

      expect(localState.errorMessage).toBe('error');
    });
  });

  describe('DELETE_ENTRY', () => {
    beforeEach(() => {
      localState.currentProjectId = 'gitlab-ce';
      localState.currentBranchId = 'master';
      localState.trees['gitlab-ce/master'] = {
        tree: [],
      };
    });

    it('sets deleted flag', () => {
      localState.entries.filePath = {
        deleted: false,
      };

      mutations.DELETE_ENTRY(localState, 'filePath');

      expect(localState.entries.filePath.deleted).toBe(true);
    });

    it('removes from root tree', () => {
      localState.entries.filePath = {
        path: 'filePath',
        deleted: false,
      };
      localState.trees['gitlab-ce/master'].tree.push(localState.entries.filePath);

      mutations.DELETE_ENTRY(localState, 'filePath');

      expect(localState.trees['gitlab-ce/master'].tree).toEqual([]);
    });

    it('removes from parent tree', () => {
      localState.entries.filePath = {
        path: 'filePath',
        deleted: false,
        parentPath: 'parentPath',
      };
      localState.entries.parentPath = {
        tree: [localState.entries.filePath],
      };

      mutations.DELETE_ENTRY(localState, 'filePath');

      expect(localState.entries.parentPath.tree).toEqual([]);
    });

    it('adds to changedFiles', () => {
      localState.entries.filePath = {
        deleted: false,
      };

      mutations.DELETE_ENTRY(localState, 'filePath');

      expect(localState.changedFiles).toEqual([localState.entries.filePath]);
    });
  });

  describe('UPDATE_FILE_AFTER_COMMIT', () => {
    it('updates URLs if prevPath is set', () => {
      const f = {
        ...file(),
        path: 'test',
        prevPath: 'testing-123',
        rawPath: `${gl.TEST_HOST}/testing-123`,
        permalink: `${gl.TEST_HOST}/testing-123`,
        commitsPath: `${gl.TEST_HOST}/testing-123`,
        blamePath: `${gl.TEST_HOST}/testing-123`,
      };
      localState.entries.test = f;
      localState.changedFiles.push(f);

      mutations.UPDATE_FILE_AFTER_COMMIT(localState, { file: f, lastCommit: { commit: {} } });

      expect(f.rawPath).toBe(`${gl.TEST_HOST}/test`);
      expect(f.permalink).toBe(`${gl.TEST_HOST}/test`);
      expect(f.commitsPath).toBe(`${gl.TEST_HOST}/test`);
      expect(f.blamePath).toBe(`${gl.TEST_HOST}/test`);
    });
  });

  describe('OPEN_NEW_ENTRY_MODAL', () => {
    it('sets entryModal', () => {
      localState.entries.testPath = {
        ...file(),
      };

      mutations.OPEN_NEW_ENTRY_MODAL(localState, { type: 'test', path: 'testPath' });

      expect(localState.entryModal).toEqual({
        type: 'test',
        path: 'testPath',
        entry: localState.entries.testPath,
      });
    });
  });

  describe('RENAME_ENTRY', () => {
    beforeEach(() => {
      localState.trees = {
        'gitlab-ce/master': { tree: [] },
      };
      localState.currentProjectId = 'gitlab-ce';
      localState.currentBranchId = 'master';
      localState.entries.oldPath = {
        ...file(),
        type: 'blob',
        path: 'oldPath',
        url: `${gl.TEST_HOST}/oldPath`,
      };
    });

    it('creates new renamed entry', () => {
      mutations.RENAME_ENTRY(localState, { path: 'oldPath', name: 'newPath' });

      expect(localState.entries.newPath).toEqual({
        ...localState.entries.oldPath,
        id: 'newPath',
        name: 'newPath',
        key: 'newPath-blob-name',
        path: 'newPath',
        tempFile: true,
        prevPath: 'oldPath',
        tree: [],
        parentPath: '',
        url: `${gl.TEST_HOST}/newPath`,
        moved: jasmine.anything(),
      });
    });

    it('adds new entry to changedFiles', () => {
      mutations.RENAME_ENTRY(localState, { path: 'oldPath', name: 'newPath' });

      expect(localState.changedFiles.length).toBe(1);
      expect(localState.changedFiles[0].path).toBe('newPath');
    });

    it('sets oldEntry as moved', () => {
      mutations.RENAME_ENTRY(localState, { path: 'oldPath', name: 'newPath' });

      expect(localState.entries.oldPath.moved).toBe(true);
    });

    it('adds to parents tree', () => {
      localState.entries.oldPath.parentPath = 'parentPath';
      localState.entries.parentPath = {
        ...file(),
      };

      mutations.RENAME_ENTRY(localState, { path: 'oldPath', name: 'newPath' });

      expect(localState.entries.parentPath.tree.length).toBe(1);
    });
  });
});
