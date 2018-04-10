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
});
