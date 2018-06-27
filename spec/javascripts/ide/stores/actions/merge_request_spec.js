import store from '~/ide/stores';
import service from '~/ide/services';
import { resetStore } from '../../helpers';

describe('IDE store merge request actions', () => {
  beforeEach(() => {
    store.state.projects.abcproject = {
      mergeRequests: {},
    };
  });

  afterEach(() => {
    resetStore(store);
  });

  describe('getMergeRequestData', () => {
    beforeEach(() => {
      spyOn(service, 'getProjectMergeRequestData').and.returnValue(
        Promise.resolve({ data: { title: 'mergerequest' } }),
      );
    });

    it('calls getProjectMergeRequestData service method', done => {
      store
        .dispatch('getMergeRequestData', { projectId: 'abcproject', mergeRequestId: 1 })
        .then(() => {
          expect(service.getProjectMergeRequestData).toHaveBeenCalledWith('abcproject', 1);

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

  describe('getMergeRequestChanges', () => {
    beforeEach(() => {
      spyOn(service, 'getProjectMergeRequestChanges').and.returnValue(
        Promise.resolve({ data: { title: 'mergerequest' } }),
      );

      store.state.projects.abcproject.mergeRequests['1'] = { changes: [] };
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

  describe('getMergeRequestVersions', () => {
    beforeEach(() => {
      spyOn(service, 'getProjectMergeRequestVersions').and.returnValue(
        Promise.resolve({ data: [{ id: 789 }] }),
      );

      store.state.projects.abcproject.mergeRequests['1'] = { versions: [] };
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
});
