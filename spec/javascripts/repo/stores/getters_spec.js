import * as getters from '~/repo/stores/getters';
import state from '~/repo/stores/state';
import { file } from '../helpers';

describe('Multi-file store getters', () => {
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('treeList', () => {
    it('returns flat tree list', () => {
      localState.tree.push(file('1'));
      localState.tree[0].tree.push(file('2'));
      localState.tree[0].tree[0].tree.push(file('3'));

      const treeList = getters.treeList(localState);

      expect(treeList.length).toBe(3);
      expect(treeList[1].name).toBe(localState.tree[0].tree[0].name);
      expect(treeList[2].name).toBe(localState.tree[0].tree[0].tree[0].name);
    });
  });

  describe('changedFiles', () => {
    it('returns a list of changed opened files', () => {
      localState.openFiles.push(file());
      localState.openFiles.push(file('changed'));
      localState.openFiles[1].changed = true;

      const changedFiles = getters.changedFiles(localState);

      expect(changedFiles.length).toBe(1);
      expect(changedFiles[0].name).toBe('changed');
    });
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

      expect(getters.activeFile(localState)).toBeUndefined();
    });
  });

  describe('activeFileExtension', () => {
    it('returns the file extension for the current active file', () => {
      localState.openFiles.push(file('active'));
      localState.openFiles[0].active = true;
      localState.openFiles[0].path = 'test.js';

      expect(getters.activeFileExtension(localState)).toBe('.js');

      localState.openFiles[0].path = 'test.es6.js';

      expect(getters.activeFileExtension(localState)).toBe('.js');
    });
  });

  describe('isCollapsed', () => {
    it('returns true if state has open files', () => {
      localState.openFiles.push(file());

      expect(getters.isCollapsed(localState)).toBeTruthy();
    });

    it('returns false if state has no open files', () => {
      expect(getters.isCollapsed(localState)).toBeFalsy();
    });
  });

  describe('canEditFile', () => {
    beforeEach(() => {
      localState.onTopOfBranch = true;
      localState.canCommit = true;

      localState.openFiles.push(file());
      localState.openFiles[0].active = true;
    });

    it('returns true if user can commit and has open files', () => {
      expect(getters.canEditFile(localState)).toBeTruthy();
    });

    it('returns false if user can commit and has no open files', () => {
      localState.openFiles = [];

      expect(getters.canEditFile(localState)).toBeFalsy();
    });

    it('returns false if user can commit and active file is binary', () => {
      localState.openFiles[0].binary = true;

      expect(getters.canEditFile(localState)).toBeFalsy();
    });

    it('returns false if user cant commit', () => {
      localState.canCommit = false;

      expect(getters.canEditFile(localState)).toBeFalsy();
    });

    it('returns false if user can commit but on a branch', () => {
      localState.onTopOfBranch = false;

      expect(getters.canEditFile(localState)).toBeFalsy();
    });
  });
});
