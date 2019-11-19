import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import store from '~/ide/stores';
import actions, {
  getMergeRequestData,
  getMergeRequestChanges,
  getMergeRequestVersions,
  openMergeRequest,
} from '~/ide/stores/actions/merge_request';
import service from '~/ide/services';
import { activityBarViews } from '~/ide/constants';
import { resetStore } from '../../helpers';

const TEST_PROJECT = 'abcproject';
const TEST_PROJECT_ID = 17;

describe('IDE store merge request actions', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    store.state.projects[TEST_PROJECT] = {
      id: TEST_PROJECT_ID,
      mergeRequests: {},
    };
  });

  afterEach(() => {
    mock.restore();
    resetStore(store);
  });

  describe('getMergeRequestsForBranch', () => {
    describe('success', () => {
      const mrData = { iid: 2, source_branch: 'bar' };
      const mockData = [mrData];

      describe('base case', () => {
        beforeEach(() => {
          spyOn(service, 'getProjectMergeRequests').and.callThrough();
          mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests/).reply(200, mockData);
        });

        it('calls getProjectMergeRequests service method', done => {
          store
            .dispatch('getMergeRequestsForBranch', { projectId: TEST_PROJECT, branchId: 'bar' })
            .then(() => {
              expect(service.getProjectMergeRequests).toHaveBeenCalledWith(TEST_PROJECT, {
                source_branch: 'bar',
                source_project_id: TEST_PROJECT_ID,
                order_by: 'created_at',
                per_page: 1,
              });

              done();
            })
            .catch(done.fail);
        });

        it('sets the "Merge Request" Object', done => {
          store
            .dispatch('getMergeRequestsForBranch', { projectId: TEST_PROJECT, branchId: 'bar' })
            .then(() => {
              expect(store.state.projects.abcproject.mergeRequests).toEqual({
                '2': jasmine.objectContaining(mrData),
              });
              done();
            })
            .catch(done.fail);
        });

        it('sets "Current Merge Request" object to the most recent MR', done => {
          store
            .dispatch('getMergeRequestsForBranch', { projectId: TEST_PROJECT, branchId: 'bar' })
            .then(() => {
              expect(store.state.currentMergeRequestId).toEqual('2');
              done();
            })
            .catch(done.fail);
        });
      });

      describe('no merge requests for branch available case', () => {
        beforeEach(() => {
          spyOn(service, 'getProjectMergeRequests').and.callThrough();
          mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests/).reply(200, []);
        });

        it('does not fail if there are no merge requests for current branch', done => {
          store
            .dispatch('getMergeRequestsForBranch', { projectId: TEST_PROJECT, branchId: 'foo' })
            .then(() => {
              expect(store.state.projects[TEST_PROJECT].mergeRequests).toEqual({});
              expect(store.state.currentMergeRequestId).toEqual('');
              done();
            })
            .catch(done.fail);
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests/).networkError();
      });

      it('flashes message, if error', done => {
        const flashSpy = spyOnDependency(actions, 'flash');

        store
          .dispatch('getMergeRequestsForBranch', { projectId: TEST_PROJECT, branchId: 'bar' })
          .then(() => {
            fail('Expected getMergeRequestsForBranch to throw an error');
          })
          .catch(() => {
            expect(flashSpy).toHaveBeenCalled();
            expect(flashSpy.calls.argsFor(0)[0]).toEqual('Error fetching merge requests for bar');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('getMergeRequestData', () => {
    describe('success', () => {
      beforeEach(() => {
        spyOn(service, 'getProjectMergeRequestData').and.callThrough();

        mock
          .onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1/)
          .reply(200, { title: 'mergerequest' });
      });

      it('calls getProjectMergeRequestData service method', done => {
        store
          .dispatch('getMergeRequestData', { projectId: TEST_PROJECT, mergeRequestId: 1 })
          .then(() => {
            expect(service.getProjectMergeRequestData).toHaveBeenCalledWith(TEST_PROJECT, 1, {
              render_html: true,
            });

            done();
          })
          .catch(done.fail);
      });

      it('sets the Merge Request Object', done => {
        store
          .dispatch('getMergeRequestData', { projectId: TEST_PROJECT, mergeRequestId: 1 })
          .then(() => {
            expect(store.state.currentMergeRequestId).toBe(1);
            expect(store.state.projects[TEST_PROJECT].mergeRequests['1'].title).toBe(
              'mergerequest',
            );

            done();
          })
          .catch(done.fail);
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1/).networkError();
      });

      it('dispatches error action', done => {
        const dispatch = jasmine.createSpy('dispatch');

        getMergeRequestData(
          {
            commit() {},
            dispatch,
            state: store.state,
          },
          { projectId: TEST_PROJECT, mergeRequestId: 1 },
        )
          .then(done.fail)
          .catch(() => {
            expect(dispatch).toHaveBeenCalledWith('setErrorMessage', {
              text: 'An error occurred whilst loading the merge request.',
              action: jasmine.any(Function),
              actionText: 'Please try again',
              actionPayload: {
                projectId: TEST_PROJECT,
                mergeRequestId: 1,
                force: false,
              },
            });

            done();
          });
      });
    });
  });

  describe('getMergeRequestChanges', () => {
    beforeEach(() => {
      store.state.projects[TEST_PROJECT].mergeRequests['1'] = { changes: [] };
    });

    describe('success', () => {
      beforeEach(() => {
        spyOn(service, 'getProjectMergeRequestChanges').and.callThrough();

        mock
          .onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1\/changes/)
          .reply(200, { title: 'mergerequest' });
      });

      it('calls getProjectMergeRequestChanges service method', done => {
        store
          .dispatch('getMergeRequestChanges', { projectId: TEST_PROJECT, mergeRequestId: 1 })
          .then(() => {
            expect(service.getProjectMergeRequestChanges).toHaveBeenCalledWith(TEST_PROJECT, 1);

            done();
          })
          .catch(done.fail);
      });

      it('sets the Merge Request Changes Object', done => {
        store
          .dispatch('getMergeRequestChanges', { projectId: TEST_PROJECT, mergeRequestId: 1 })
          .then(() => {
            expect(store.state.projects[TEST_PROJECT].mergeRequests['1'].changes.title).toBe(
              'mergerequest',
            );
            done();
          })
          .catch(done.fail);
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1\/changes/).networkError();
      });

      it('dispatches error action', done => {
        const dispatch = jasmine.createSpy('dispatch');

        getMergeRequestChanges(
          {
            commit() {},
            dispatch,
            state: store.state,
          },
          { projectId: TEST_PROJECT, mergeRequestId: 1 },
        )
          .then(done.fail)
          .catch(() => {
            expect(dispatch).toHaveBeenCalledWith('setErrorMessage', {
              text: 'An error occurred whilst loading the merge request changes.',
              action: jasmine.any(Function),
              actionText: 'Please try again',
              actionPayload: {
                projectId: TEST_PROJECT,
                mergeRequestId: 1,
                force: false,
              },
            });

            done();
          });
      });
    });
  });

  describe('getMergeRequestVersions', () => {
    beforeEach(() => {
      store.state.projects[TEST_PROJECT].mergeRequests['1'] = { versions: [] };
    });

    describe('success', () => {
      beforeEach(() => {
        mock
          .onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1\/versions/)
          .reply(200, [{ id: 789 }]);
        spyOn(service, 'getProjectMergeRequestVersions').and.callThrough();
      });

      it('calls getProjectMergeRequestVersions service method', done => {
        store
          .dispatch('getMergeRequestVersions', { projectId: TEST_PROJECT, mergeRequestId: 1 })
          .then(() => {
            expect(service.getProjectMergeRequestVersions).toHaveBeenCalledWith(TEST_PROJECT, 1);

            done();
          })
          .catch(done.fail);
      });

      it('sets the Merge Request Versions Object', done => {
        store
          .dispatch('getMergeRequestVersions', { projectId: TEST_PROJECT, mergeRequestId: 1 })
          .then(() => {
            expect(store.state.projects[TEST_PROJECT].mergeRequests['1'].versions.length).toBe(1);
            done();
          })
          .catch(done.fail);
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/projects\/abcproject\/merge_requests\/1\/versions/).networkError();
      });

      it('dispatches error action', done => {
        const dispatch = jasmine.createSpy('dispatch');

        getMergeRequestVersions(
          {
            commit() {},
            dispatch,
            state: store.state,
          },
          { projectId: TEST_PROJECT, mergeRequestId: 1 },
        )
          .then(done.fail)
          .catch(() => {
            expect(dispatch).toHaveBeenCalledWith('setErrorMessage', {
              text: 'An error occurred whilst loading the merge request version data.',
              action: jasmine.any(Function),
              actionText: 'Please try again',
              actionPayload: {
                projectId: TEST_PROJECT,
                mergeRequestId: 1,
                force: false,
              },
            });

            done();
          });
      });
    });
  });

  describe('openMergeRequest', () => {
    const mr = {
      projectId: TEST_PROJECT,
      targetProjectId: 'defproject',
      mergeRequestId: 2,
    };
    let testMergeRequest;
    let testMergeRequestChanges;

    beforeEach(() => {
      testMergeRequest = {
        source_branch: 'abcbranch',
      };
      testMergeRequestChanges = {
        changes: [],
      };
      store.state.entries = {
        foo: {
          type: 'blob',
        },
        bar: {
          type: 'blob',
        },
      };

      store.state.currentProjectId = 'test/test';
      store.state.currentBranchId = 'master';

      store.state.projects['test/test'] = {
        branches: {
          master: {
            commit: {
              id: '7297abc',
            },
          },
          abcbranch: {
            commit: {
              id: '29020fc',
            },
          },
        },
      };

      const originalDispatch = store.dispatch;

      spyOn(store, 'dispatch').and.callFake((type, payload) => {
        switch (type) {
          case 'getMergeRequestData':
            return Promise.resolve(testMergeRequest);
          case 'getMergeRequestChanges':
            return Promise.resolve(testMergeRequestChanges);
          case 'getFiles':
          case 'getMergeRequestVersions':
          case 'getBranchData':
          case 'setFileMrChange':
            return Promise.resolve();
          default:
            return originalDispatch(type, payload);
        }
      });
      spyOn(service, 'getFileData').and.callFake(() =>
        Promise.resolve({
          headers: {},
        }),
      );
    });

    it('dispatch actions for merge request data', done => {
      openMergeRequest(store, mr)
        .then(() => {
          expect(store.dispatch.calls.allArgs()).toEqual([
            ['getMergeRequestData', mr],
            ['setCurrentBranchId', testMergeRequest.source_branch],
            [
              'getBranchData',
              {
                projectId: mr.projectId,
                branchId: testMergeRequest.source_branch,
              },
            ],
            [
              'getFiles',
              {
                projectId: mr.projectId,
                branchId: testMergeRequest.source_branch,
              },
            ],
            ['getMergeRequestVersions', mr],
            ['getMergeRequestChanges', mr],
          ]);
        })
        .then(done)
        .catch(done.fail);
    });

    it('updates activity bar view and gets file data, if changes are found', done => {
      store.state.entries.foo = {
        url: 'test',
        type: 'blob',
      };
      store.state.entries.bar = {
        url: 'test',
        type: 'blob',
      };

      testMergeRequestChanges.changes = [
        { new_path: 'foo', path: 'foo' },
        { new_path: 'bar', path: 'bar' },
      ];

      openMergeRequest(store, mr)
        .then(() => {
          expect(store.dispatch).toHaveBeenCalledWith(
            'updateActivityBarView',
            activityBarViews.review,
          );

          testMergeRequestChanges.changes.forEach((change, i) => {
            expect(store.dispatch).toHaveBeenCalledWith('setFileMrChange', {
              file: store.state.entries[change.new_path],
              mrChange: change,
            });

            expect(store.dispatch).toHaveBeenCalledWith('getFileData', {
              path: change.new_path,
              makeFileActive: i === 0,
              openFile: true,
            });
          });

          expect(store.state.openFiles.length).toBe(testMergeRequestChanges.changes.length);
        })
        .then(done)
        .catch(done.fail);
    });

    it('flashes message, if error', done => {
      const flashSpy = spyOnDependency(actions, 'flash');
      store.dispatch.and.returnValue(Promise.reject());

      openMergeRequest(store, mr)
        .then(() => {
          fail('Expected openMergeRequest to throw an error');
        })
        .catch(() => {
          expect(flashSpy).toHaveBeenCalledWith(jasmine.any(String));
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
