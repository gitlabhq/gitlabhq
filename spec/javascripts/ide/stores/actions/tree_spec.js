import MockAdapter from 'axios-mock-adapter';
import testAction from 'spec/helpers/vuex_action_helper';
import { showTreeEntry, getFiles } from '~/ide/stores/actions/tree';
import * as types from '~/ide/stores/mutation_types';
import axios from '~/lib/utils/axios_utils';
import store from '~/ide/stores';
import service from '~/ide/services';
import router from '~/ide/ide_router';
import { file, resetStore, createEntriesFromPaths } from '../../helpers';

describe('Multi-file store tree actions', () => {
  let projectTree;
  let mock;

  const basicCallParameters = {
    endpoint: 'rootEndpoint',
    projectId: 'abcproject',
    branch: 'master',
    branchId: 'master',
  };

  beforeEach(() => {
    spyOn(router, 'push');

    mock = new MockAdapter(axios);

    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'master';
    store.state.projects.abcproject = {
      web_url: '',
      branches: {
        master: {
          workingReference: '1',
        },
      },
    };
  });

  afterEach(() => {
    mock.restore();
    resetStore(store);
  });

  describe('getFiles', () => {
    describe('success', () => {
      beforeEach(() => {
        spyOn(service, 'getFiles').and.callThrough();

        mock
          .onGet(/(.*)/)
          .replyOnce(200, [
            'file.txt',
            'folder/fileinfolder.js',
            'folder/subfolder/fileinsubfolder.js',
          ]);
      });

      it('calls service getFiles', done => {
        store
          .dispatch('getFiles', basicCallParameters)
          .then(() => {
            expect(service.getFiles).toHaveBeenCalledWith('', 'master');

            done();
          })
          .catch(done.fail);
      });

      it('adds data into tree', done => {
        store
          .dispatch('getFiles', basicCallParameters)
          .then(() => {
            projectTree = store.state.trees['abcproject/master'];
            expect(projectTree.tree.length).toBe(2);
            expect(projectTree.tree[0].type).toBe('tree');
            expect(projectTree.tree[0].tree[1].name).toBe('fileinfolder.js');
            expect(projectTree.tree[1].type).toBe('blob');
            expect(projectTree.tree[0].tree[0].tree[0].type).toBe('blob');
            expect(projectTree.tree[0].tree[0].tree[0].name).toBe('fileinsubfolder.js');

            done();
          })
          .catch(done.fail);
      });
    });

    describe('error', () => {
      it('dispatches branch not found actions when response is 404', done => {
        const dispatch = jasmine.createSpy('dispatchSpy');

        store.state.projects = {
          'abc/def': {
            web_url: `${gl.TEST_HOST}/files`,
          },
        };

        mock.onGet(/(.*)/).replyOnce(404);

        getFiles(
          {
            commit() {},
            dispatch,
            state: store.state,
          },
          {
            projectId: 'abc/def',
            branchId: 'master-testing',
          },
        )
          .then(done.fail)
          .catch(() => {
            expect(dispatch.calls.argsFor(0)).toEqual([
              'showBranchNotFoundError',
              'master-testing',
            ]);
            done();
          });
      });

      it('dispatches error action', done => {
        const dispatch = jasmine.createSpy('dispatchSpy');

        store.state.projects = {
          'abc/def': {
            web_url: `${gl.TEST_HOST}/files`,
          },
        };

        mock.onGet(/(.*)/).replyOnce(500);

        getFiles(
          {
            commit() {},
            dispatch,
            state: store.state,
          },
          {
            projectId: 'abc/def',
            branchId: 'master-testing',
          },
        )
          .then(done.fail)
          .catch(() => {
            expect(dispatch).toHaveBeenCalledWith('setErrorMessage', {
              text: 'An error occured whilst loading all the files.',
              action: jasmine.any(Function),
              actionText: 'Please try again',
              actionPayload: { projectId: 'abc/def', branchId: 'master-testing' },
            });
            done();
          });
      });
    });
  });

  describe('toggleTreeOpen', () => {
    let tree;

    beforeEach(() => {
      tree = file('testing', '1', 'tree');
      store.state.entries[tree.path] = tree;
    });

    it('toggles the tree open', done => {
      store
        .dispatch('toggleTreeOpen', tree.path)
        .then(() => {
          expect(tree.opened).toBeTruthy();

          done();
        })
        .catch(done.fail);
    });
  });

  describe('showTreeEntry', () => {
    beforeEach(() => {
      const paths = [
        'grandparent',
        'ancestor',
        'grandparent/parent',
        'grandparent/aunt',
        'grandparent/parent/child.txt',
        'grandparent/aunt/cousing.txt',
      ];

      Object.assign(store.state.entries, createEntriesFromPaths(paths));
    });

    it('opens the parents', done => {
      testAction(
        showTreeEntry,
        'grandparent/parent/child.txt',
        store.state,
        [{ type: types.SET_TREE_OPEN, payload: 'grandparent/parent' }],
        [{ type: 'showTreeEntry', payload: 'grandparent/parent' }],
        done,
      );
    });
  });
});
