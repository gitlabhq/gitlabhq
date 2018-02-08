import Vue from 'vue';
import * as urlUtils from '~/lib/utils/url_utility';
import store from '~/ide/stores';
import service from '~/ide/services';
import { resetStore, file } from '../helpers';

describe('Multi-file store actions', () => {
  afterEach(() => {
    resetStore(store);
  });

  describe('redirectToUrl', () => {
    it('calls visitUrl', (done) => {
      spyOn(urlUtils, 'visitUrl');

      store.dispatch('redirectToUrl', 'test')
        .then(() => {
          expect(urlUtils.visitUrl).toHaveBeenCalledWith('test');

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

  describe('discardAllChanges', () => {
    beforeEach(() => {
      const f = file('discardAll');
      f.changed = true;

      store.state.openFiles.push(f);
      store.state.changedFiles.push(f);
    });

    it('discards changes in file', (done) => {
      store.dispatch('discardAllChanges')
        .then(() => {
          expect(store.state.openFiles.changed).toBeFalsy();
        })
        .then(done)
        .catch(done.fail);
    });

    it('removes all files from changedFiles state', (done) => {
      store.dispatch('discardAllChanges')
        .then(() => {
          expect(store.state.changedFiles.length).toBe(0);
          expect(store.state.openFiles.length).toBe(1);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('closeAllFiles', () => {
    beforeEach(() => {
      store.state.openFiles.push(file('closeAll'));
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
    it('toggles edit mode', (done) => {
      store.state.editMode = true;

      store.dispatch('toggleEditMode')
        .then(() => {
          expect(store.state.editMode).toBeFalsy();

          done();
        }).catch(done.fail);
    });

    it('sets preview mode', (done) => {
      store.state.currentBlobView = 'repo-editor';
      store.state.editMode = true;

      store.dispatch('toggleEditMode')
        .then(Vue.nextTick)
        .then(() => {
          expect(store.state.currentBlobView).toBe('repo-preview');

          done();
        }).catch(done.fail);
    });
  });

  describe('toggleBlobView', () => {
    it('sets edit mode view if in edit mode', (done) => {
      store.dispatch('toggleBlobView')
        .then(() => {
          expect(store.state.currentBlobView).toBe('repo-editor');

          done();
        })
        .catch(done.fail);
    });

    it('sets preview mode view if not in edit mode', (done) => {
      store.state.editMode = false;

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
      store.state.currentProjectId = 'abcproject';
      store.state.currentBranchId = 'master';
      store.state.projects.abcproject = {
        branches: {
          master: {
            workingReference: '1',
          },
        },
      };
    });

    it('calls service', (done) => {
      spyOn(service, 'getBranchData').and.returnValue(Promise.resolve({
        data: {
          commit: { id: '123' },
        },
      }));

      store.dispatch('checkCommitStatus')
        .then(() => {
          expect(service.getBranchData).toHaveBeenCalledWith('abcproject', 'master');

          done();
        })
        .catch(done.fail);
    });

    it('returns true if current ref does not equal returned ID', (done) => {
      spyOn(service, 'getBranchData').and.returnValue(Promise.resolve({
        data: {
          commit: { id: '123' },
        },
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
        data: {
          commit: { id: '1' },
        },
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
    let payload;

    beforeEach(() => {
      spyOn(window, 'scrollTo');

      document.body.innerHTML += '<div class="flash-container"></div>';

      store.state.currentProjectId = 'abcproject';
      store.state.currentBranchId = 'master';
      store.state.projects.abcproject = {
        web_url: 'webUrl',
        branches: {
          master: {
            workingReference: '1',
          },
        },
      };

      payload = {
        branch: 'master',
      };
    });

    afterEach(() => {
      document.querySelector('.flash-container').remove();
    });

    describe('success', () => {
      beforeEach(() => {
        spyOn(service, 'commit').and.returnValue(Promise.resolve({
          data: {
            id: '123456',
            short_id: '123',
            message: 'test message',
            committed_date: 'date',
            stats: {
              additions: '1',
              deletions: '2',
            },
          },
        }));
      });

      it('calls service', (done) => {
        store.dispatch('commitChanges', { payload, newMr: false })
          .then(() => {
            expect(service.commit).toHaveBeenCalledWith('abcproject', payload);

            done();
          }).catch(done.fail);
      });

      it('sets last Commit Msg', (done) => {
        store.dispatch('commitChanges', { payload, newMr: false })
          .then(() => {
            expect(store.state.lastCommitMsg).toBe(
              'Your changes have been committed. Commit 123 with 1 additions, 2 deletions.',
            );

            done();
          }).catch(done.fail);
      });

      it('adds commit data to changed files', (done) => {
        const changedFile = file();

        store.state.changedFiles.push(changedFile);

        store.dispatch('commitChanges', { payload, newMr: false })
          .then(() => {
            expect(changedFile.lastCommit.message).toBe('test message');

            done();
          }).catch(done.fail);
      });

      it('scrolls to top of page', (done) => {
        store.dispatch('commitChanges', { payload, newMr: false })
          .then(() => {
            expect(window.scrollTo).toHaveBeenCalledWith(0, 0);

            done();
          }).catch(done.fail);
      });

      it('redirects to new merge request page', (done) => {
        spyOn(urlUtils, 'visitUrl');

        store.dispatch('commitChanges', { payload, newMr: true })
          .then(() => {
            expect(urlUtils.visitUrl).toHaveBeenCalledWith('webUrl/merge_requests/new?merge_request%5Bsource_branch%5D=master');

            done();
          }).catch(done.fail);
      });
    });

    describe('failed', () => {
      beforeEach(() => {
        spyOn(service, 'commit').and.returnValue(Promise.resolve({
          data: {
            message: 'failed message',
          },
        }));
      });

      it('shows failed message', (done) => {
        store.dispatch('commitChanges', { payload, newMr: false })
          .then(() => {
            const alert = document.querySelector('.flash-container');

            expect(alert.textContent.trim()).toBe(
              'failed message',
            );

            done();
          }).catch(done.fail);
      });
    });
  });

  describe('createTempEntry', () => {
    beforeEach(() => {
      store.state.trees['abcproject/mybranch'] = {
        tree: [],
      };
      store.state.projects.abcproject = {
        web_url: '',
      };
    });

    it('creates a temp tree', (done) => {
      const projectTree = store.state.trees['abcproject/mybranch'];

      store.dispatch('createTempEntry', {
        projectId: 'abcproject',
        branchId: 'mybranch',
        parent: projectTree,
        name: 'test',
        type: 'tree',
      })
      .then(() => {
        const baseTree = projectTree.tree;
        expect(baseTree.length).toBe(1);
        expect(baseTree[0].tempFile).toBeTruthy();
        expect(baseTree[0].type).toBe('tree');

        done();
      })
      .catch(done.fail);
    });

    it('creates temp file', (done) => {
      const projectTree = store.state.trees['abcproject/mybranch'];

      store.dispatch('createTempEntry', {
        projectId: 'abcproject',
        branchId: 'mybranch',
        parent: projectTree,
        name: 'test',
        type: 'blob',
      })
      .then(() => {
        const baseTree = projectTree.tree;
        expect(baseTree.length).toBe(1);
        expect(baseTree[0].tempFile).toBeTruthy();
        expect(baseTree[0].type).toBe('blob');

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
