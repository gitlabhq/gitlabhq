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
});
