import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import store from '~/ide/stores';
import {
  getMergeRequestData,
  getMergeRequestChanges,
  getMergeRequestVersions,
} from '~/ide/stores/actions/merge_request';
import service from '~/ide/services';
import { resetStore } from '../../helpers';

describe('IDE store merge request actions', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    store.state.projects.abcproject = {
      mergeRequests: {},
    };
  });

  afterEach(() => {
    mock.restore();
    resetStore(store);
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
          .dispatch('getMergeRequestData', { projectId: 'abcproject', mergeRequestId: 1 })
          .then(() => {
            expect(service.getProjectMergeRequestData).toHaveBeenCalledWith('abcproject', 1, {
              render_html: true,
            });

            done();
          })
          .catch(done.fail);
      });

      it('sets the Merge Request Object', done => {
        store
          .dispatch('getMergeRequestData', { projectId: 'abcproject', mergeRequestId: 1 })
          .then(() => {
            expect(store.state.projects.abcproject.mergeRequests['1'].title).toBe('mergerequest');
            expect(store.state.currentMergeRequestId).toBe(1);

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
          { projectId: 'abcproject', mergeRequestId: 1 },
        )
          .then(done.fail)
          .catch(() => {
            expect(dispatch).toHaveBeenCalledWith('setErrorMessage', {
              text: 'An error occured whilst loading the merge request.',
              action: jasmine.any(Function),
              actionText: 'Please try again',
              actionPayload: {
                projectId: 'abcproject',
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
      store.state.projects.abcproject.mergeRequests['1'] = { changes: [] };
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
          .dispatch('getMergeRequestChanges', { projectId: 'abcproject', mergeRequestId: 1 })
          .then(() => {
            expect(service.getProjectMergeRequestChanges).toHaveBeenCalledWith('abcproject', 1);

            done();
          })
          .catch(done.fail);
      });

      it('sets the Merge Request Changes Object', done => {
        store
          .dispatch('getMergeRequestChanges', { projectId: 'abcproject', mergeRequestId: 1 })
          .then(() => {
            expect(store.state.projects.abcproject.mergeRequests['1'].changes.title).toBe(
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
          { projectId: 'abcproject', mergeRequestId: 1 },
        )
          .then(done.fail)
          .catch(() => {
            expect(dispatch).toHaveBeenCalledWith('setErrorMessage', {
              text: 'An error occured whilst loading the merge request changes.',
              action: jasmine.any(Function),
              actionText: 'Please try again',
              actionPayload: {
                projectId: 'abcproject',
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
      store.state.projects.abcproject.mergeRequests['1'] = { versions: [] };
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
          .dispatch('getMergeRequestVersions', { projectId: 'abcproject', mergeRequestId: 1 })
          .then(() => {
            expect(service.getProjectMergeRequestVersions).toHaveBeenCalledWith('abcproject', 1);

            done();
          })
          .catch(done.fail);
      });

      it('sets the Merge Request Versions Object', done => {
        store
          .dispatch('getMergeRequestVersions', { projectId: 'abcproject', mergeRequestId: 1 })
          .then(() => {
            expect(store.state.projects.abcproject.mergeRequests['1'].versions.length).toBe(1);
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
          { projectId: 'abcproject', mergeRequestId: 1 },
        )
          .then(done.fail)
          .catch(() => {
            expect(dispatch).toHaveBeenCalledWith('setErrorMessage', {
              text: 'An error occured whilst loading the merge request version data.',
              action: jasmine.any(Function),
              actionText: 'Please try again',
              actionPayload: {
                projectId: 'abcproject',
                mergeRequestId: 1,
                force: false,
              },
            });

            done();
          });
      });
    });
  });
});
