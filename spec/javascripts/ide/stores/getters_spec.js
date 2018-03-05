import * as getters from 'ee/ide/stores/getters';
import state from 'ee/ide/stores/state';
import { file } from '../helpers';

describe('Multi-file store getters', () => {
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

  describe('addedFiles', () => {
    it('returns a list of added files', () => {
      localState.openFiles.push(file());
      localState.changedFiles.push(file('added'));
      localState.changedFiles[0].changed = true;
      localState.changedFiles[0].tempFile = true;

      const modifiedFiles = getters.addedFiles(localState);

      expect(modifiedFiles.length).toBe(1);
      expect(modifiedFiles[0].name).toBe('added');
    });
  });
});
