import mutations from '~/repo/stores/mutations';
import state from '~/repo/stores/state';
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

      expect(localState.editMode).toBeTruthy();

      mutations.TOGGLE_EDIT_MODE(localState);

      expect(localState.editMode).toBeFalsy();
    });
  });

  describe('TOGGLE_DISCARD_POPUP', () => {
    it('sets discardPopupOpen', () => {
      mutations.TOGGLE_DISCARD_POPUP(localState, true);

      expect(localState.discardPopupOpen).toBeTruthy();

      mutations.TOGGLE_DISCARD_POPUP(localState, false);

      expect(localState.discardPopupOpen).toBeFalsy();
    });
  });

  describe('SET_COMMIT_REF', () => {
    it('sets currentRef', () => {
      mutations.SET_COMMIT_REF(localState, '123');

      expect(localState.currentRef).toBe('123');
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

  describe('SET_PREVIOUS_URL', () => {
    it('sets previousUrl', () => {
      mutations.SET_PREVIOUS_URL(localState, 'testing');

      expect(localState.previousUrl).toBe('testing');
    });
  });
});
