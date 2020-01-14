import MockAdapter from 'axios-mock-adapter';
import actions, {
  stageAllChanges,
  unstageAllChanges,
  toggleFileFinder,
  setCurrentBranchId,
  setEmptyStateSvgs,
  updateActivityBarView,
  updateTempFlagForEntry,
  setErrorMessage,
  deleteEntry,
  renameEntry,
  getBranchData,
  createTempEntry,
  discardAllChanges,
} from '~/ide/stores/actions';
import axios from '~/lib/utils/axios_utils';
import { createStore } from '~/ide/stores';
import * as types from '~/ide/stores/mutation_types';
import router from '~/ide/ide_router';
import { file } from '../helpers';
import testAction from '../../helpers/vuex_action_helper';
import eventHub from '~/ide/eventhub';

describe('Multi-file store actions', () => {
  let store;

  beforeEach(() => {
    store = createStore();

    spyOn(store, 'commit').and.callThrough();
    spyOn(store, 'dispatch').and.callThrough();
    spyOn(router, 'push');
  });

  describe('redirectToUrl', () => {
    it('calls visitUrl', done => {
      const visitUrl = spyOnDependency(actions, 'visitUrl');

      store
        .dispatch('redirectToUrl', 'test')
        .then(() => {
          expect(visitUrl).toHaveBeenCalledWith('test');

          done();
        })
        .catch(done.fail);
    });
  });

  describe('setInitialData', () => {
    it('commits initial data', done => {
      store
        .dispatch('setInitialData', { canCommit: true })
        .then(() => {
          expect(store.state.canCommit).toBeTruthy();
          done();
        })
        .catch(done.fail);
    });
  });

  describe('discardAllChanges', () => {
    const paths = ['to_discard', 'another_one_to_discard'];

    beforeEach(() => {
      paths.forEach(path => {
        const f = file(path);
        f.changed = true;

        store.state.openFiles.push(f);
        store.state.changedFiles.push(f);
        store.state.entries[f.path] = f;
      });
    });

    it('discards all changes in file', () => {
      const expectedCalls = paths.map(path => ['restoreOriginalFile', path]);

      discardAllChanges(store);

      expect(store.dispatch.calls.allArgs()).toEqual(jasmine.arrayContaining(expectedCalls));
    });

    it('removes all files from changedFiles state', done => {
      store
        .dispatch('discardAllChanges')
        .then(() => {
          expect(store.state.changedFiles.length).toBe(0);
          expect(store.state.openFiles.length).toBe(2);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('closeAllFiles', () => {
    beforeEach(() => {
      const f = file('closeAll');
      store.state.openFiles.push(f);
      store.state.openFiles[0].opened = true;
      store.state.entries[f.path] = f;
    });

    it('closes all open files', done => {
      store
        .dispatch('closeAllFiles')
        .then(() => {
          expect(store.state.openFiles.length).toBe(0);

          done();
        })
        .catch(done.fail);
    });
  });

  describe('createTempEntry', () => {
    beforeEach(() => {
      document.body.innerHTML += '<div class="flash-container"></div>';

      store.state.currentProjectId = 'abcproject';
      store.state.currentBranchId = 'mybranch';

      store.state.trees['abcproject/mybranch'] = {
        tree: [],
      };
      store.state.projects.abcproject = {
        web_url: '',
      };
    });

    afterEach(() => {
      document.querySelector('.flash-container').remove();
    });

    describe('tree', () => {
      it('creates temp tree', done => {
        store
          .dispatch('createTempEntry', {
            branchId: store.state.currentBranchId,
            name: 'test',
            type: 'tree',
          })
          .then(() => {
            const entry = store.state.entries.test;

            expect(entry).not.toBeNull();
            expect(entry.type).toBe('tree');

            done();
          })
          .catch(done.fail);
      });

      it('creates new folder inside another tree', done => {
        const tree = {
          type: 'tree',
          name: 'testing',
          path: 'testing',
          tree: [],
        };

        store.state.entries[tree.path] = tree;

        store
          .dispatch('createTempEntry', {
            branchId: store.state.currentBranchId,
            name: 'testing/test',
            type: 'tree',
          })
          .then(() => {
            expect(tree.tree[0].tempFile).toBeTruthy();
            expect(tree.tree[0].name).toBe('test');
            expect(tree.tree[0].type).toBe('tree');

            done();
          })
          .catch(done.fail);
      });

      it('does not create new tree if already exists', done => {
        const tree = {
          type: 'tree',
          path: 'testing',
          tempFile: false,
          tree: [],
        };

        store.state.entries[tree.path] = tree;

        store
          .dispatch('createTempEntry', {
            branchId: store.state.currentBranchId,
            name: 'testing',
            type: 'tree',
          })
          .then(() => {
            expect(store.state.entries[tree.path].tempFile).toEqual(false);
            expect(document.querySelector('.flash-alert')).not.toBeNull();

            done();
          })
          .catch(done.fail);
      });
    });

    describe('blob', () => {
      it('creates temp file', done => {
        store
          .dispatch('createTempEntry', {
            name: 'test',
            branchId: 'mybranch',
            type: 'blob',
          })
          .then(f => {
            expect(f.tempFile).toBeTruthy();
            expect(store.state.trees['abcproject/mybranch'].tree.length).toBe(1);

            done();
          })
          .catch(done.fail);
      });

      it('adds tmp file to open files', done => {
        store
          .dispatch('createTempEntry', {
            name: 'test',
            branchId: 'mybranch',
            type: 'blob',
          })
          .then(f => {
            expect(store.state.openFiles.length).toBe(1);
            expect(store.state.openFiles[0].name).toBe(f.name);

            done();
          })
          .catch(done.fail);
      });

      it('adds tmp file to changed files', done => {
        store
          .dispatch('createTempEntry', {
            name: 'test',
            branchId: 'mybranch',
            type: 'blob',
          })
          .then(f => {
            expect(store.state.changedFiles.length).toBe(1);
            expect(store.state.changedFiles[0].name).toBe(f.name);

            done();
          })
          .catch(done.fail);
      });

      it('sets tmp file as active', done => {
        testAction(
          createTempEntry,
          {
            name: 'test',
            branchId: 'mybranch',
            type: 'blob',
          },
          store.state,
          [
            { type: types.CREATE_TMP_ENTRY, payload: jasmine.any(Object) },
            { type: types.TOGGLE_FILE_OPEN, payload: 'test' },
            { type: types.ADD_FILE_TO_CHANGED, payload: 'test' },
          ],
          jasmine.arrayContaining([
            {
              type: 'setFileActive',
              payload: 'test',
            },
            {
              type: 'triggerFilesChange',
            },
          ]),
          done,
        );
      });

      it('creates flash message if file already exists', done => {
        const f = file('test', '1', 'blob');
        store.state.trees['abcproject/mybranch'].tree = [f];
        store.state.entries[f.path] = f;

        store
          .dispatch('createTempEntry', {
            name: 'test',
            branchId: 'mybranch',
            type: 'blob',
          })
          .then(() => {
            expect(document.querySelector('.flash-alert')).not.toBeNull();

            done();
          })
          .catch(done.fail);
      });

      it('bursts unused seal', done => {
        store
          .dispatch('createTempEntry', {
            name: 'test',
            branchId: 'mybranch',
            type: 'blob',
          })
          .then(() => {
            expect(store.state.unusedSeal).toBe(false);

            done();
          })
          .catch(done.fail);
      });
    });
  });

  describe('scrollToTab', () => {
    it('focuses the current active element', done => {
      document.body.innerHTML +=
        '<div id="tabs"><div class="active"><div class="repo-tab"></div></div></div>';
      const el = document.querySelector('.repo-tab');
      spyOn(el, 'focus');

      store
        .dispatch('scrollToTab')
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

  describe('stage/unstageAllChanges', () => {
    let file1;
    let file2;

    beforeEach(() => {
      file1 = { ...file('test'), content: 'changed test', raw: 'test' };
      file2 = { ...file('test2'), content: 'changed test2', raw: 'test2' };

      store.state.openFiles = [file1];
      store.state.changedFiles = [file1];
      store.state.stagedFiles = [{ ...file2, content: 'staged test' }];

      store.state.entries = {
        [file1.path]: { ...file1 },
        [file2.path]: { ...file2 },
      };
    });

    describe('stageAllChanges', () => {
      it('adds all files from changedFiles to stagedFiles', () => {
        stageAllChanges(store);

        expect(store.commit.calls.allArgs()).toEqual([
          [types.SET_LAST_COMMIT_MSG, ''],
          [types.STAGE_CHANGE, jasmine.objectContaining({ path: file1.path })],
        ]);
      });

      it('opens pending tab if a change exists in that file', () => {
        stageAllChanges(store);

        expect(store.dispatch.calls.allArgs()).toEqual([
          [
            'openPendingTab',
            { file: { ...file1, staged: true, changed: true }, keyPrefix: 'staged' },
          ],
        ]);
      });

      it('does not open pending tab if no change exists in that file', () => {
        store.state.entries[file1.path].content = 'test';
        store.state.stagedFiles = [file1];
        store.state.changedFiles = [store.state.entries[file1.path]];

        stageAllChanges(store);

        expect(store.dispatch).not.toHaveBeenCalled();
      });
    });

    describe('unstageAllChanges', () => {
      it('removes all files from stagedFiles after unstaging', () => {
        unstageAllChanges(store);

        expect(store.commit.calls.allArgs()).toEqual([
          [types.UNSTAGE_CHANGE, jasmine.objectContaining({ path: file2.path })],
        ]);
      });

      it('opens pending tab if a change exists in that file', () => {
        unstageAllChanges(store);

        expect(store.dispatch.calls.allArgs()).toEqual([
          ['openPendingTab', { file: file1, keyPrefix: 'unstaged' }],
        ]);
      });

      it('does not open pending tab if no change exists in that file', () => {
        store.state.entries[file1.path].content = 'test';
        store.state.stagedFiles = [file1];
        store.state.changedFiles = [store.state.entries[file1.path]];

        unstageAllChanges(store);

        expect(store.dispatch).not.toHaveBeenCalled();
      });
    });
  });

  describe('updateViewer', () => {
    it('updates viewer state', done => {
      store
        .dispatch('updateViewer', 'diff')
        .then(() => {
          expect(store.state.viewer).toBe('diff');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('updateActivityBarView', () => {
    it('commits UPDATE_ACTIVITY_BAR_VIEW', done => {
      testAction(
        updateActivityBarView,
        'test',
        {},
        [{ type: 'UPDATE_ACTIVITY_BAR_VIEW', payload: 'test' }],
        [],
        done,
      );
    });
  });

  describe('setEmptyStateSvgs', () => {
    it('commits setEmptyStateSvgs', done => {
      testAction(
        setEmptyStateSvgs,
        'svg',
        {},
        [{ type: 'SET_EMPTY_STATE_SVGS', payload: 'svg' }],
        [],
        done,
      );
    });
  });

  describe('updateTempFlagForEntry', () => {
    it('commits UPDATE_TEMP_FLAG', done => {
      const f = {
        ...file(),
        path: 'test',
        tempFile: true,
      };
      store.state.entries[f.path] = f;

      testAction(
        updateTempFlagForEntry,
        { file: f, tempFile: false },
        store.state,
        [{ type: 'UPDATE_TEMP_FLAG', payload: { path: f.path, tempFile: false } }],
        [],
        done,
      );
    });

    it('commits UPDATE_TEMP_FLAG and dispatches for parent', done => {
      const parent = {
        ...file(),
        path: 'testing',
      };
      const f = {
        ...file(),
        path: 'test',
        parentPath: 'testing',
      };
      store.state.entries[parent.path] = parent;
      store.state.entries[f.path] = f;

      testAction(
        updateTempFlagForEntry,
        { file: f, tempFile: false },
        store.state,
        [{ type: 'UPDATE_TEMP_FLAG', payload: { path: f.path, tempFile: false } }],
        [{ type: 'updateTempFlagForEntry', payload: { file: parent, tempFile: false } }],
        done,
      );
    });

    it('does not dispatch for parent, if parent does not exist', done => {
      const f = {
        ...file(),
        path: 'test',
        parentPath: 'testing',
      };
      store.state.entries[f.path] = f;

      testAction(
        updateTempFlagForEntry,
        { file: f, tempFile: false },
        store.state,
        [{ type: 'UPDATE_TEMP_FLAG', payload: { path: f.path, tempFile: false } }],
        [],
        done,
      );
    });
  });

  describe('setCurrentBranchId', () => {
    it('commits setCurrentBranchId', done => {
      testAction(
        setCurrentBranchId,
        'branchId',
        {},
        [{ type: 'SET_CURRENT_BRANCH', payload: 'branchId' }],
        [],
        done,
      );
    });
  });

  describe('toggleFileFinder', () => {
    it('commits TOGGLE_FILE_FINDER', done => {
      testAction(
        toggleFileFinder,
        true,
        null,
        [{ type: 'TOGGLE_FILE_FINDER', payload: true }],
        [],
        done,
      );
    });
  });

  describe('setErrorMessage', () => {
    it('commis error messsage', done => {
      testAction(
        setErrorMessage,
        'error',
        null,
        [{ type: types.SET_ERROR_MESSAGE, payload: 'error' }],
        [],
        done,
      );
    });
  });

  describe('deleteEntry', () => {
    it('commits entry deletion', done => {
      store.state.entries.path = 'testing';

      testAction(
        deleteEntry,
        'path',
        store.state,
        [{ type: types.DELETE_ENTRY, payload: 'path' }],
        [
          { type: 'burstUnusedSeal' },
          { type: 'stageChange', payload: 'path' },
          { type: 'triggerFilesChange' },
        ],
        done,
      );
    });

    it('does not delete a folder after it is emptied', done => {
      const testFolder = {
        type: 'tree',
        tree: [],
      };
      const testEntry = {
        path: 'testFolder/entry-to-delete',
        parentPath: 'testFolder',
        opened: false,
        tree: [],
      };
      testFolder.tree.push(testEntry);
      store.state.entries = {
        testFolder,
        'testFolder/entry-to-delete': testEntry,
      };

      testAction(
        deleteEntry,
        'testFolder/entry-to-delete',
        store.state,
        [{ type: types.DELETE_ENTRY, payload: 'testFolder/entry-to-delete' }],
        [
          { type: 'burstUnusedSeal' },
          { type: 'stageChange', payload: 'testFolder/entry-to-delete' },
          { type: 'triggerFilesChange' },
        ],
        done,
      );
    });

    it('if renamed, reverts the rename before deleting', () => {
      const testEntry = {
        path: 'test',
        name: 'test',
        prevPath: 'lorem/ipsum',
        prevName: 'ipsum',
        prevParentPath: 'lorem',
      };

      store.state.entries = { test: testEntry };
      testAction(
        deleteEntry,
        testEntry.path,
        store.state,
        [],
        [
          {
            type: 'renameEntry',
            payload: {
              path: testEntry.path,
              name: testEntry.prevName,
              parentPath: testEntry.prevParentPath,
            },
          },
          {
            type: 'deleteEntry',
            payload: testEntry.prevPath,
          },
        ],
      );
    });

    it('bursts unused seal', done => {
      store.state.entries.test = file('test');

      store
        .dispatch('deleteEntry', 'test')
        .then(() => {
          expect(store.state.unusedSeal).toBe(false);

          done();
        })
        .catch(done.fail);
    });
  });

  describe('renameEntry', () => {
    describe('purging of file model cache', () => {
      beforeEach(() => {
        spyOn(eventHub, '$emit');
      });

      it('does not purge model cache for temporary entries that got renamed', done => {
        Object.assign(store.state.entries, {
          test: {
            ...file('test'),
            key: 'foo-key',
            type: 'blob',
            tempFile: true,
          },
        });

        store
          .dispatch('renameEntry', {
            path: 'test',
            name: 'new',
          })
          .then(() => {
            expect(eventHub.$emit.calls.allArgs()).not.toContain(
              'editor.update.model.dispose.foo-bar',
            );
          })
          .then(done)
          .catch(done.fail);
      });

      it('purges model cache for renamed entry', done => {
        Object.assign(store.state.entries, {
          test: {
            ...file('test'),
            key: 'foo-key',
            type: 'blob',
            tempFile: false,
          },
        });

        store
          .dispatch('renameEntry', {
            path: 'test',
            name: 'new',
          })
          .then(() => {
            expect(eventHub.$emit).toHaveBeenCalled();
            expect(eventHub.$emit).toHaveBeenCalledWith(`editor.update.model.dispose.foo-key`);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('single entry', () => {
      let origEntry;
      let renamedEntry;

      beforeEach(() => {
        // Need to insert both because `testAction` doesn't actually call the mutation
        origEntry = file('orig', 'orig', 'blob');
        renamedEntry = {
          ...file('renamed', 'renamed', 'blob'),
          prevKey: origEntry.key,
          prevName: origEntry.name,
          prevPath: origEntry.path,
        };

        Object.assign(store.state.entries, {
          orig: origEntry,
          renamed: renamedEntry,
        });
      });

      it('by default renames an entry and adds to changed', done => {
        testAction(
          renameEntry,
          { path: 'orig', name: 'renamed' },
          store.state,
          [
            {
              type: types.RENAME_ENTRY,
              payload: {
                path: 'orig',
                name: 'renamed',
                parentPath: undefined,
              },
            },
            {
              type: types.ADD_FILE_TO_CHANGED,
              payload: 'renamed',
            },
          ],
          [{ type: 'burstUnusedSeal' }, { type: 'triggerFilesChange' }],
          done,
        );
      });

      it('if not changed, completely unstages entry if renamed to original', done => {
        testAction(
          renameEntry,
          { path: 'renamed', name: 'orig' },
          store.state,
          [
            {
              type: types.RENAME_ENTRY,
              payload: {
                path: 'renamed',
                name: 'orig',
                parentPath: undefined,
              },
            },
            {
              type: types.REMOVE_FILE_FROM_STAGED_AND_CHANGED,
              payload: origEntry,
            },
          ],
          [{ type: 'triggerFilesChange' }],
          done,
        );
      });

      it('if already in changed, does not add to change', done => {
        store.state.changedFiles.push(renamedEntry);

        testAction(
          renameEntry,
          { path: 'orig', name: 'renamed' },
          store.state,
          [jasmine.objectContaining({ type: types.RENAME_ENTRY })],
          [{ type: 'triggerFilesChange' }],
          done,
        );
      });

      it('routes to the renamed file if the original file has been opened', done => {
        Object.assign(store.state.entries.orig, {
          opened: true,
          url: '/foo-bar.md',
        });

        store
          .dispatch('renameEntry', {
            path: 'orig',
            name: 'renamed',
          })
          .then(() => {
            expect(router.push.calls.count()).toBe(1);
            expect(router.push).toHaveBeenCalledWith(`/project/foo-bar.md`);
          })
          .then(done)
          .catch(done.fail);
      });

      it('bursts unused seal', done => {
        store
          .dispatch('renameEntry', {
            path: 'orig',
            name: 'renamed',
          })
          .then(() => {
            expect(store.state.unusedSeal).toBe(false);

            done();
          })
          .catch(done.fail);
      });
    });

    describe('folder', () => {
      let folder;
      let file1;
      let file2;

      beforeEach(() => {
        folder = file('folder', 'folder', 'tree');
        file1 = file('file-1', 'file-1', 'blob', folder);
        file2 = file('file-2', 'file-2', 'blob', folder);

        folder.tree = [file1, file2];

        Object.assign(store.state.entries, {
          [folder.path]: folder,
          [file1.path]: file1,
          [file2.path]: file2,
        });
      });

      it('updates entries in a folder correctly, when folder is renamed', done => {
        store
          .dispatch('renameEntry', {
            path: 'folder',
            name: 'new-folder',
          })
          .then(() => {
            const keys = Object.keys(store.state.entries);

            expect(keys.length).toBe(3);
            expect(keys.indexOf('new-folder')).toBe(0);
            expect(keys.indexOf('new-folder/file-1')).toBe(1);
            expect(keys.indexOf('new-folder/file-2')).toBe(2);
          })
          .then(done)
          .catch(done.fail);
      });

      it('discards renaming of an entry if the root folder is renamed back to a previous name', done => {
        const rootFolder = file('old-folder', 'old-folder', 'tree');
        const testEntry = file('test', 'test', 'blob', rootFolder);

        Object.assign(store.state, {
          entries: {
            'old-folder': {
              ...rootFolder,
              tree: [testEntry],
            },
            'old-folder/test': testEntry,
          },
        });

        store
          .dispatch('renameEntry', {
            path: 'old-folder',
            name: 'new-folder',
          })
          .then(() => {
            const { entries } = store.state;

            expect(Object.keys(entries).length).toBe(2);
            expect(entries['old-folder']).toBeUndefined();
            expect(entries['old-folder/test']).toBeUndefined();

            expect(entries['new-folder']).toBeDefined();
            expect(entries['new-folder/test']).toEqual(
              jasmine.objectContaining({
                path: 'new-folder/test',
                name: 'test',
                prevPath: 'old-folder/test',
                prevName: 'test',
              }),
            );
          })
          .then(() =>
            store.dispatch('renameEntry', {
              path: 'new-folder',
              name: 'old-folder',
            }),
          )
          .then(() => {
            const { entries } = store.state;

            expect(Object.keys(entries).length).toBe(2);
            expect(entries['new-folder']).toBeUndefined();
            expect(entries['new-folder/test']).toBeUndefined();

            expect(entries['old-folder']).toBeDefined();
            expect(entries['old-folder/test']).toEqual(
              jasmine.objectContaining({
                path: 'old-folder/test',
                name: 'test',
                prevPath: undefined,
                prevName: undefined,
              }),
            );
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('getBranchData', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('error', () => {
      let dispatch;
      let callParams;

      beforeEach(() => {
        callParams = [
          {
            commit() {},
            state: store.state,
          },
          {
            projectId: 'abc/def',
            branchId: 'master-testing',
          },
        ];
        dispatch = jasmine.createSpy('dispatchSpy');
        document.body.innerHTML += '<div class="flash-container"></div>';
      });

      afterEach(() => {
        document.querySelector('.flash-container').remove();
      });

      it('passes the error further unchanged without dispatching any action when response is 404', done => {
        mock.onGet(/(.*)/).replyOnce(404);

        getBranchData(...callParams)
          .then(done.fail)
          .catch(e => {
            expect(dispatch.calls.count()).toEqual(0);
            expect(e.response.status).toEqual(404);
            expect(document.querySelector('.flash-alert')).toBeNull();
            done();
          });
      });

      it('does not pass the error further and flashes an alert if error is not 404', done => {
        mock.onGet(/(.*)/).replyOnce(418);

        getBranchData(...callParams)
          .then(done.fail)
          .catch(e => {
            expect(dispatch.calls.count()).toEqual(0);
            expect(e.response).toBeUndefined();
            expect(document.querySelector('.flash-alert')).not.toBeNull();
            done();
          });
      });
    });
  });
});
