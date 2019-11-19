import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import store from '~/ide/stores';
import * as actions from '~/ide/stores/actions/file';
import * as types from '~/ide/stores/mutation_types';
import service from '~/ide/services';
import router from '~/ide/ide_router';
import eventHub from '~/ide/eventhub';
import { file, resetStore } from '../../helpers';
import testAction from '../../../helpers/vuex_action_helper';

const RELATIVE_URL_ROOT = '/gitlab';

describe('IDE store file actions', () => {
  let mock;
  let originalGon;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    originalGon = window.gon;
    window.gon = {
      ...window.gon,
      relative_url_root: RELATIVE_URL_ROOT,
    };

    spyOn(router, 'push');
  });

  afterEach(() => {
    mock.restore();
    resetStore(store);
    window.gon = originalGon;
  });

  describe('closeFile', () => {
    let localFile;

    beforeEach(() => {
      localFile = file('testFile');
      localFile.active = true;
      localFile.opened = true;
      localFile.parentTreeUrl = 'parentTreeUrl';

      store.state.openFiles.push(localFile);
      store.state.entries[localFile.path] = localFile;
    });

    it('closes open files', done => {
      store
        .dispatch('closeFile', localFile)
        .then(() => {
          expect(localFile.opened).toBeFalsy();
          expect(localFile.active).toBeFalsy();
          expect(store.state.openFiles.length).toBe(0);

          done();
        })
        .catch(done.fail);
    });

    it('closes file even if file has changes', done => {
      store.state.changedFiles.push(localFile);

      store
        .dispatch('closeFile', localFile)
        .then(Vue.nextTick)
        .then(() => {
          expect(store.state.openFiles.length).toBe(0);
          expect(store.state.changedFiles.length).toBe(1);

          done();
        })
        .catch(done.fail);
    });

    it('closes file & opens next available file', done => {
      const f = {
        ...file('newOpenFile'),
        url: '/newOpenFile',
      };

      store.state.openFiles.push(f);
      store.state.entries[f.path] = f;

      store
        .dispatch('closeFile', localFile)
        .then(Vue.nextTick)
        .then(() => {
          expect(router.push).toHaveBeenCalledWith(`/project${f.url}`);

          done();
        })
        .catch(done.fail);
    });

    it('removes file if it pending', done => {
      store.state.openFiles.push({
        ...localFile,
        pending: true,
      });

      store
        .dispatch('closeFile', localFile)
        .then(() => {
          expect(store.state.openFiles.length).toBe(0);

          done();
        })
        .catch(done.fail);
    });
  });

  describe('setFileActive', () => {
    let localFile;
    let scrollToTabSpy;
    let oldScrollToTab;

    beforeEach(() => {
      scrollToTabSpy = jasmine.createSpy('scrollToTab');
      oldScrollToTab = store._actions.scrollToTab; // eslint-disable-line
      store._actions.scrollToTab = [scrollToTabSpy]; // eslint-disable-line

      localFile = file('setThisActive');

      store.state.entries[localFile.path] = localFile;
    });

    afterEach(() => {
      store._actions.scrollToTab = oldScrollToTab; // eslint-disable-line
    });

    it('calls scrollToTab', () => {
      const dispatch = jasmine.createSpy();

      actions.setFileActive(
        { commit() {}, state: store.state, getters: store.getters, dispatch },
        localFile.path,
      );

      expect(dispatch).toHaveBeenCalledWith('scrollToTab');
    });

    it('commits SET_FILE_ACTIVE', () => {
      const commit = jasmine.createSpy();

      actions.setFileActive(
        { commit, state: store.state, getters: store.getters, dispatch() {} },
        localFile.path,
      );

      expect(commit).toHaveBeenCalledWith('SET_FILE_ACTIVE', {
        path: localFile.path,
        active: true,
      });
    });

    it('sets current active file to not active', () => {
      const f = file('newActive');
      store.state.entries[f.path] = f;
      localFile.active = true;
      store.state.openFiles.push(localFile);

      const commit = jasmine.createSpy();

      actions.setFileActive(
        { commit, state: store.state, getters: store.getters, dispatch() {} },
        f.path,
      );

      expect(commit).toHaveBeenCalledWith('SET_FILE_ACTIVE', {
        path: localFile.path,
        active: false,
      });
    });
  });

  describe('getFileData', () => {
    let localFile;

    beforeEach(() => {
      spyOn(service, 'getFileData').and.callThrough();

      localFile = file(`newCreate-${Math.random()}`);
      store.state.entries[localFile.path] = localFile;

      store.state.currentProjectId = 'test/test';
      store.state.currentBranchId = 'master';

      store.state.projects['test/test'] = {
        branches: {
          master: {
            commit: {
              id: '7297abc',
            },
          },
        },
      };
    });

    describe('success', () => {
      beforeEach(() => {
        mock.onGet(`${RELATIVE_URL_ROOT}/test/test/7297abc/${localFile.path}`).replyOnce(
          200,
          {
            blame_path: 'blame_path',
            commits_path: 'commits_path',
            permalink: 'permalink',
            raw_path: 'raw_path',
            binary: false,
            html: '123',
            render_error: '',
          },
          {
            'page-title': 'testing getFileData',
          },
        );
      });

      it('calls the service', done => {
        store
          .dispatch('getFileData', { path: localFile.path })
          .then(() => {
            expect(service.getFileData).toHaveBeenCalledWith(
              `${RELATIVE_URL_ROOT}/test/test/7297abc/${localFile.path}`,
            );

            done();
          })
          .catch(done.fail);
      });

      it('sets the file data', done => {
        store
          .dispatch('getFileData', { path: localFile.path })
          .then(() => {
            expect(localFile.blamePath).toBe('blame_path');

            done();
          })
          .catch(done.fail);
      });

      it('sets document title with the branchId', done => {
        store
          .dispatch('getFileData', { path: localFile.path })
          .then(() => {
            expect(document.title).toBe(`${localFile.path} · master · test/test · GitLab`);
            done();
          })
          .catch(done.fail);
      });

      it('sets the file as active', done => {
        store
          .dispatch('getFileData', { path: localFile.path })
          .then(() => {
            expect(localFile.active).toBeTruthy();

            done();
          })
          .catch(done.fail);
      });

      it('sets the file not as active if we pass makeFileActive false', done => {
        store
          .dispatch('getFileData', { path: localFile.path, makeFileActive: false })
          .then(() => {
            expect(localFile.active).toBeFalsy();

            done();
          })
          .catch(done.fail);
      });

      it('adds the file to open files', done => {
        store
          .dispatch('getFileData', { path: localFile.path })
          .then(() => {
            expect(store.state.openFiles.length).toBe(1);
            expect(store.state.openFiles[0].name).toBe(localFile.name);

            done();
          })
          .catch(done.fail);
      });
    });

    describe('Re-named success', () => {
      beforeEach(() => {
        localFile = file(`newCreate-${Math.random()}`);
        localFile.url = `project/getFileDataURL`;
        localFile.prevPath = 'old-dull-file';
        localFile.path = 'new-shiny-file';
        store.state.entries[localFile.path] = localFile;

        mock.onGet(`${RELATIVE_URL_ROOT}/test/test/7297abc/old-dull-file`).replyOnce(
          200,
          {
            blame_path: 'blame_path',
            commits_path: 'commits_path',
            permalink: 'permalink',
            raw_path: 'raw_path',
            binary: false,
            html: '123',
            render_error: '',
          },
          {
            'page-title': 'testing old-dull-file',
          },
        );
      });

      it('sets document title considering `prevPath` on a file', done => {
        store
          .dispatch('getFileData', { path: localFile.path })
          .then(() => {
            expect(document.title).toBe(`new-shiny-file · master · test/test · GitLab`);

            done();
          })
          .catch(done.fail);
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${RELATIVE_URL_ROOT}/test/test/7297abc/${localFile.path}`).networkError();
      });

      it('dispatches error action', done => {
        const dispatch = jasmine.createSpy('dispatch');

        actions
          .getFileData(
            { state: store.state, commit() {}, dispatch, getters: store.getters },
            { path: localFile.path },
          )
          .then(() => {
            expect(dispatch).toHaveBeenCalledWith('setErrorMessage', {
              text: 'An error occurred whilst loading the file.',
              action: jasmine.any(Function),
              actionText: 'Please try again',
              actionPayload: {
                path: localFile.path,
                makeFileActive: true,
              },
            });

            done();
          })
          .catch(done.fail);
      });
    });
  });

  describe('getRawFileData', () => {
    let tmpFile;

    beforeEach(() => {
      spyOn(service, 'getRawFileData').and.callThrough();

      tmpFile = file('tmpFile');
      store.state.entries[tmpFile.path] = tmpFile;
    });

    describe('success', () => {
      beforeEach(() => {
        mock.onGet(/(.*)/).replyOnce(200, 'raw');
      });

      it('calls getRawFileData service method', done => {
        store
          .dispatch('getRawFileData', { path: tmpFile.path })
          .then(() => {
            expect(service.getRawFileData).toHaveBeenCalledWith(tmpFile);

            done();
          })
          .catch(done.fail);
      });

      it('updates file raw data', done => {
        store
          .dispatch('getRawFileData', { path: tmpFile.path })
          .then(() => {
            expect(tmpFile.raw).toBe('raw');

            done();
          })
          .catch(done.fail);
      });

      it('calls also getBaseRawFileData service method', done => {
        spyOn(service, 'getBaseRawFileData').and.returnValue(Promise.resolve('baseraw'));

        store.state.currentProjectId = 'gitlab-org/gitlab-ce';
        store.state.currentMergeRequestId = '1';
        store.state.projects = {
          'gitlab-org/gitlab-ce': {
            mergeRequests: {
              1: {
                baseCommitSha: 'SHA',
              },
            },
          },
        };

        tmpFile.mrChange = { new_file: false };

        store
          .dispatch('getRawFileData', { path: tmpFile.path })
          .then(() => {
            expect(service.getBaseRawFileData).toHaveBeenCalledWith(tmpFile, 'SHA');
            expect(tmpFile.baseRaw).toBe('baseraw');

            done();
          })
          .catch(done.fail);
      });
    });

    describe('return JSON', () => {
      beforeEach(() => {
        mock.onGet(/(.*)/).replyOnce(200, JSON.stringify({ test: '123' }));
      });

      it('does not parse returned JSON', done => {
        store
          .dispatch('getRawFileData', { path: tmpFile.path })
          .then(() => {
            expect(tmpFile.raw).toEqual('{"test":"123"}');

            done();
          })
          .catch(done.fail);
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/(.*)/).networkError();
      });

      it('dispatches error action', done => {
        const dispatch = jasmine.createSpy('dispatch');

        actions
          .getRawFileData({ state: store.state, commit() {}, dispatch }, { path: tmpFile.path })
          .then(done.fail)
          .catch(() => {
            expect(dispatch).toHaveBeenCalledWith('setErrorMessage', {
              text: 'An error occurred whilst loading the file content.',
              action: jasmine.any(Function),
              actionText: 'Please try again',
              actionPayload: {
                path: tmpFile.path,
              },
            });

            done();
          });
      });
    });
  });

  describe('changeFileContent', () => {
    let tmpFile;

    beforeEach(() => {
      tmpFile = file('tmpFile');
      tmpFile.content = '\n';
      tmpFile.raw = '\n';
      store.state.entries[tmpFile.path] = tmpFile;
    });

    it('updates file content', done => {
      store
        .dispatch('changeFileContent', {
          path: tmpFile.path,
          content: 'content\n',
        })
        .then(() => {
          expect(tmpFile.content).toBe('content\n');

          done();
        })
        .catch(done.fail);
    });

    it('adds a newline to the end of the file if it doesnt already exist', done => {
      store
        .dispatch('changeFileContent', {
          path: tmpFile.path,
          content: 'content',
        })
        .then(() => {
          expect(tmpFile.content).toBe('content\n');

          done();
        })
        .catch(done.fail);
    });

    it('adds file into changedFiles array', done => {
      store
        .dispatch('changeFileContent', {
          path: tmpFile.path,
          content: 'content',
        })
        .then(() => {
          expect(store.state.changedFiles.length).toBe(1);

          done();
        })
        .catch(done.fail);
    });

    it('adds file once into changedFiles array', done => {
      store
        .dispatch('changeFileContent', {
          path: tmpFile.path,
          content: 'content',
        })
        .then(() =>
          store.dispatch('changeFileContent', {
            path: tmpFile.path,
            content: 'content 123',
          }),
        )
        .then(() => {
          expect(store.state.changedFiles.length).toBe(1);

          done();
        })
        .catch(done.fail);
    });

    it('removes file from changedFiles array if not changed', done => {
      store
        .dispatch('changeFileContent', {
          path: tmpFile.path,
          content: 'content\n',
        })
        .then(() =>
          store.dispatch('changeFileContent', {
            path: tmpFile.path,
            content: '\n',
          }),
        )
        .then(() => {
          expect(store.state.changedFiles.length).toBe(0);

          done();
        })
        .catch(done.fail);
    });

    it('bursts unused seal', done => {
      store
        .dispatch('changeFileContent', {
          path: tmpFile.path,
          content: 'content',
        })
        .then(() => {
          expect(store.state.unusedSeal).toBe(false);

          done();
        })
        .catch(done.fail);
    });
  });

  describe('discardFileChanges', () => {
    let tmpFile;

    beforeEach(() => {
      spyOn(eventHub, '$on');
      spyOn(eventHub, '$emit');

      tmpFile = file();
      tmpFile.content = 'testing';

      store.state.changedFiles.push(tmpFile);
      store.state.entries[tmpFile.path] = tmpFile;
    });

    it('resets file content', done => {
      store
        .dispatch('discardFileChanges', tmpFile.path)
        .then(() => {
          expect(tmpFile.content).not.toBe('testing');

          done();
        })
        .catch(done.fail);
    });

    it('removes file from changedFiles array', done => {
      store
        .dispatch('discardFileChanges', tmpFile.path)
        .then(() => {
          expect(store.state.changedFiles.length).toBe(0);

          done();
        })
        .catch(done.fail);
    });

    it('closes temp file', done => {
      tmpFile.tempFile = true;
      tmpFile.opened = true;

      store
        .dispatch('discardFileChanges', tmpFile.path)
        .then(() => {
          expect(tmpFile.opened).toBeFalsy();

          done();
        })
        .catch(done.fail);
    });

    it('does not re-open a closed temp file', done => {
      tmpFile.tempFile = true;

      expect(tmpFile.opened).toBeFalsy();

      store
        .dispatch('discardFileChanges', tmpFile.path)
        .then(() => {
          expect(tmpFile.opened).toBeFalsy();

          done();
        })
        .catch(done.fail);
    });

    it('pushes route for active file', done => {
      tmpFile.active = true;
      store.state.openFiles.push(tmpFile);

      store
        .dispatch('discardFileChanges', tmpFile.path)
        .then(() => {
          expect(router.push).toHaveBeenCalledWith(`/project${tmpFile.url}`);

          done();
        })
        .catch(done.fail);
    });

    it('emits eventHub event to dispose cached model', done => {
      store
        .dispatch('discardFileChanges', tmpFile.path)
        .then(() => {
          expect(eventHub.$emit).toHaveBeenCalled();

          done();
        })
        .catch(done.fail);
    });
  });

  describe('stageChange', () => {
    it('calls STAGE_CHANGE with file path', done => {
      testAction(
        actions.stageChange,
        'path',
        store.state,
        [
          { type: types.STAGE_CHANGE, payload: 'path' },
          { type: types.SET_LAST_COMMIT_MSG, payload: '' },
        ],
        [],
        done,
      );
    });
  });

  describe('unstageChange', () => {
    it('calls UNSTAGE_CHANGE with file path', done => {
      testAction(
        actions.unstageChange,
        'path',
        store.state,
        [{ type: types.UNSTAGE_CHANGE, payload: 'path' }],
        [],
        done,
      );
    });
  });

  describe('openPendingTab', () => {
    let f;

    beforeEach(() => {
      f = {
        ...file(),
        projectId: '123',
      };

      store.state.entries[f.path] = f;
    });

    it('makes file pending in openFiles', done => {
      store
        .dispatch('openPendingTab', { file: f, keyPrefix: 'pending' })
        .then(() => {
          expect(store.state.openFiles[0].pending).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });

    it('returns true when opened', done => {
      store
        .dispatch('openPendingTab', { file: f, keyPrefix: 'pending' })
        .then(added => {
          expect(added).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });

    it('returns false when already opened', done => {
      store.state.openFiles.push({
        ...f,
        active: true,
        key: `pending-${f.key}`,
      });

      store
        .dispatch('openPendingTab', { file: f, keyPrefix: 'pending' })
        .then(added => {
          expect(added).toBe(false);
        })
        .then(done)
        .catch(done.fail);
    });

    it('pushes router URL when added', done => {
      store.state.currentBranchId = 'master';

      store
        .dispatch('openPendingTab', { file: f, keyPrefix: 'pending' })
        .then(() => {
          expect(router.push).toHaveBeenCalledWith('/project/123/tree/master/');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('removePendingTab', () => {
    let f;

    beforeEach(() => {
      spyOn(eventHub, '$emit');

      f = {
        ...file('pendingFile'),
        pending: true,
      };
    });

    it('removes pending file from open files', done => {
      store.state.openFiles.push(f);

      store
        .dispatch('removePendingTab', f)
        .then(() => {
          expect(store.state.openFiles.length).toBe(0);
        })
        .then(done)
        .catch(done.fail);
    });

    it('emits event to dispose model', done => {
      store
        .dispatch('removePendingTab', f)
        .then(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith(`editor.update.model.dispose.${f.key}`);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('triggerFilesChange', () => {
    beforeEach(() => {
      spyOn(eventHub, '$emit');
    });

    it('emits event that files have changed', done => {
      store
        .dispatch('triggerFilesChange')
        .then(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('ide.files.change');
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
