import store from '~/repo/stores';
import service from '~/repo/services';
import { resetStore, file } from '../helpers';

describe('Multi-file store actions', () => {
  afterEach(() => {
    resetStore(store);
  });

  describe('redirectToUrl', () => {
    it('calls visitUrl', (done) => {
      spyOn(gl.utils, 'visitUrl');

      store.dispatch('redirectToUrl', 'test')
        .then(() => {
          expect(gl.utils.visitUrl).toHaveBeenCalledWith('test');

          done();
        })
        .catch(done.fail);
    });
  });

  describe('setInitialData', () => {
    it('commits initial data', (done) => {
      store.dispatch('setInitialData', { canCommit: true })
        .then(() => {
          expect(store.state.canCommit).toBeTruthy();
          done();
        })
        .catch(done.fail);
    });
  });

  describe('closeDiscardPopup', () => {
    it('closes the discard popup', (done) => {
      store.dispatch('closeDiscardPopup', false)
        .then(() => {
          expect(store.state.discardPopupOpen).toBeFalsy();

          done();
        })
        .catch(done.fail);
    });
  });

  describe('discardAllChanges', () => {
    beforeEach(() => {
      store.state.openFiles.push(file());
      store.state.openFiles[0].changed = true;
    });
  });

  describe('closeAllFiles', () => {
    beforeEach(() => {
      store.state.openFiles.push(file());
      store.state.openFiles[0].opened = true;
    });

    it('closes all open files', (done) => {
      store.dispatch('closeAllFiles')
        .then(() => {
          expect(store.state.openFiles.length).toBe(0);

          done();
        })
        .catch(done.fail);
    });
  });

  describe('toggleEditMode', () => {

  });

  describe('toggleBlobView', () => {
    it('sets edit mode view if in edit mode', (done) => {
      store.state.editMode = true;

      store.dispatch('toggleBlobView')
        .then(() => {
          expect(store.state.currentBlobView).toBe('repo-editor');

          done();
        })
        .catch(done.fail);
    });

    it('sets preview mode view if not in edit mode', (done) => {
      store.dispatch('toggleBlobView')
      .then(() => {
        expect(store.state.currentBlobView).toBe('repo-preview');

        done();
      })
      .catch(done.fail);
    });
  });

  describe('checkCommitStatus', () => {
    beforeEach(() => {
      store.state.project.id = 2;
      store.state.currentBranch = 'master';
      store.state.currentRef = '1';
    });

    it('calls service', (done) => {
      spyOn(service, 'getBranchData').and.returnValue(Promise.resolve({
        commit: { id: '123' },
      }));

      store.dispatch('checkCommitStatus')
        .then(() => {
          expect(service.getBranchData).toHaveBeenCalledWith(2, 'master');

          done();
        })
        .catch(done.fail);
    });

    it('returns true if current ref does not equal returned ID', (done) => {
      spyOn(service, 'getBranchData').and.returnValue(Promise.resolve({
        commit: { id: '123' },
      }));

      store.dispatch('checkCommitStatus')
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

      store.dispatch('checkCommitStatus')
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
      store.dispatch('createTempEntry', {
        name: 'test',
        type: 'tree',
      })
      .then(() => {
        expect(store.state.tree.length).toBe(1);
        expect(store.state.tree[0].tempFile).toBeTruthy();
        expect(store.state.tree[0].type).toBe('tree');

        done();
      })
      .catch(done.fail);
    });

    it('creates temp file', (done) => {
      store.dispatch('createTempEntry', {
        name: 'test',
        type: 'blob',
      })
      .then(() => {
        expect(store.state.tree.length).toBe(1);
        expect(store.state.tree[0].tempFile).toBeTruthy();
        expect(store.state.tree[0].type).toBe('blob');

        done();
      })
      .catch(done.fail);
    });
  });

  describe('popHistoryState', () => {

  });

  describe('scrollToTab', () => {
    it('focuses the current active element', (done) => {
      document.body.innerHTML += '<div id="tabs"><div class="active"><div class="repo-tab"></div></div></div>';
      const el = document.querySelector('.repo-tab');
      spyOn(el, 'focus');

      store.dispatch('scrollToTab')
        .then(() => {
          setTimeout(() => {
            expect(el.focus).toHaveBeenCalled();

            document.getElementById('tabs').remove();

            done();
          });
        })
        .catch(done.fail);
    });
  });
});
