import mutations from 'ee/ide/stores/mutations';
import state from 'ee/ide/stores/state';
import { file } from '../helpers';

describe('Multi-file store mutations', () => {
  let localState;
  let entry;

  beforeEach(() => {
    localState = state();
    entry = file();
  });

  describe('SET_INITIAL_DATA', () => {
    it('sets all initial data', () => {
      mutations.SET_INITIAL_DATA(localState, {
        test: 'test',
      });

      expect(localState.test).toBe('test');
    });
  });

  describe('SET_PREVIEW_MODE', () => {
    it('sets currentBlobView to repo-preview', () => {
      mutations.SET_PREVIEW_MODE(localState);

      expect(localState.currentBlobView).toBe('repo-preview');

      localState.currentBlobView = 'testing';

      mutations.SET_PREVIEW_MODE(localState);

      expect(localState.currentBlobView).toBe('repo-preview');
    });
  });

  describe('SET_EDIT_MODE', () => {
    it('sets currentBlobView to repo-editor', () => {
      mutations.SET_EDIT_MODE(localState);

      expect(localState.currentBlobView).toBe('repo-editor');

      localState.currentBlobView = 'testing';

      mutations.SET_EDIT_MODE(localState);

      expect(localState.currentBlobView).toBe('repo-editor');
    });
  });

  describe('TOGGLE_LOADING', () => {
    it('toggles loading of entry', () => {
      mutations.TOGGLE_LOADING(localState, entry);

      expect(entry.loading).toBeTruthy();

      mutations.TOGGLE_LOADING(localState, entry);

      expect(entry.loading).toBeFalsy();
    });
  });

  describe('TOGGLE_EDIT_MODE', () => {
    it('toggles editMode', () => {
      mutations.TOGGLE_EDIT_MODE(localState);

      expect(localState.editMode).toBeFalsy();

      mutations.TOGGLE_EDIT_MODE(localState);

      expect(localState.editMode).toBeTruthy();
    });
  });

  describe('SET_ROOT', () => {
    it('sets isRoot & initialRoot', () => {
      mutations.SET_ROOT(localState, true);

      expect(localState.isRoot).toBeTruthy();
      expect(localState.isInitialRoot).toBeTruthy();

      mutations.SET_ROOT(localState, false);

      expect(localState.isRoot).toBeFalsy();
      expect(localState.isInitialRoot).toBeFalsy();
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
});
