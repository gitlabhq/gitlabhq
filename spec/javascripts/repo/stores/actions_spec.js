import * as actions from '~/repo/stores/actions';
import state from '~/repo/stores/state';
import service from '~/repo/services';
import testAction, { testWithDispatch } from '../../helpers/vuex_action_helper';
import { file } from '../helpers';

describe('Multi-file store actions', () => {
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('redirectToUrl', () => {
    it('calls visitUrl', () => {
      spyOn(gl.utils, 'visitUrl');

      actions.redirectToUrl('test');

      expect(gl.utils.visitUrl).toHaveBeenCalledWith('test');
    });
  });

  describe('setInitialData', () => {
    it('commits initial data', (done) => {
      testAction(
        actions.setInitialData,
        { canCommit: true },
        localState,
        [
          { type: 'SET_INITIAL_DATA', payload: { canCommit: true } },
        ],
        done,
      );
    });
  });

  describe('closeDiscardPopup', () => {
    it('closes the discard popup', (done) => {
      testAction(
        actions.closeDiscardPopup,
        false,
        localState,
        [
          { type: 'TOGGLE_DISCARD_POPUP', payload: false },
        ],
        done,
      );
    });
  });

  describe('discardAllChanges', () => {
    beforeEach(() => {
      localState.openFiles.push(file());
      localState.openFiles[0].changed = true;
    });
  });

  describe('closeAllFiles', () => {
    beforeEach(() => {
      localState.openFiles.push(file());
      localState.openFiles[0].changed = true;
    });

    it('closes all open files', (done) => {
      testWithDispatch(
        actions.closeAllFiles,
        localState.openFiles[0],
        localState,
        [
          { type: 'closeFile', payload: { file: localState.openFiles[0] } },
        ],
        done,
      );
    });
  });

  describe('toggleEditMode', () => {

  });

  describe('toggleBlobView', () => {
    it('sets edit mode view if in edit mode', (done) => {
      localState.editMode = true;

      testAction(
        actions.toggleBlobView,
        null,
        localState,
        [
          { type: 'SET_EDIT_MODE' },
        ],
        done,
      );
    });

    it('sets preview mode view if not in edit mode', (done) => {
      testAction(
        actions.toggleBlobView,
        null,
        localState,
        [
          { type: 'SET_PREVIEW_MODE' },
        ],
        done,
      );
    });
  });

  describe('checkCommitStatus', () => {
    beforeEach(() => {
      localState.project.id = 2;
      localState.currentBranch = 'master';
      localState.currentRef = '1';
    });

    it('calls service', () => {
      spyOn(service, 'getBranchData').and.returnValue(Promise.resolve({
        commit: { id: '123' },
      }));

      actions.checkCommitStatus({ state: localState });

      expect(service.getBranchData).toHaveBeenCalledWith(2, 'master');
    });

    it('returns true if current ref does not equal returned ID', (done) => {
      spyOn(service, 'getBranchData').and.returnValue(Promise.resolve({
        commit: { id: '123' },
      }));

      actions.checkCommitStatus({ state: localState })
        .then((val) => {
          expect(val).toBeTruthy();

          done();
        })
        .catch(done.fail);
    });

    it('returns false if current ref equals returned ID', (done) => {
      spyOn(service, 'getBranchData').and.returnValue(Promise.resolve({
        commit: { id: '1' },
      }));

      actions.checkCommitStatus({ state: localState })
        .then((val) => {
          expect(val).toBeFalsy();

          done();
        })
        .catch(done.fail);
    });
  });

  describe('commitChanges', () => {

  });

  describe('createTempEntry', () => {
    it('creates a temp tree', (done) => {
      testWithDispatch(
        actions.createTempEntry,
        { name: 'test', type: 'tree' },
        localState,
        [
          { type: 'createTempTree', payload: 'test' },
        ],
        done,
      );
    });

    it('creates temp file', (done) => {
      testWithDispatch(
        actions.createTempEntry,
        { name: 'test', type: 'blob' },
        localState,
        [
          {
            type: 'createTempFile',
            payload: {
              tree: localState,
              name: 'test',
              base64: false,
              content: '',
            },
          },
        ],
        done,
      );
    });
  });

  describe('popHistoryState', () => {

  });

  describe('scrollToTab', () => {
    it('focuses the current active element', (done) => {
      document.body.innerHTML += '<div id="tabs"><div class="active"><div class="repo-tab"></div></div></div>';
      const el = document.querySelector('.repo-tab');
      spyOn(el, 'focus');

      actions.scrollToTab();

      setTimeout(() => {
        expect(el.focus).toHaveBeenCalled();

        document.getElementById('tabs').remove();

        done();
      });
    });
  });
});
