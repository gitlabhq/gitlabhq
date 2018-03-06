import store from 'ee/ide/stores';
import service from 'ee/ide/services';
import { resetStore } from '../../helpers';

describe('Multi-file store branch actions', () => {
  afterEach(() => {
    resetStore(store);
  });

  describe('createNewBranch', () => {
    beforeEach(() => {
      spyOn(service, 'createBranch').and.returnValue(Promise.resolve({
        json: () => ({
          name: 'testing',
        }),
      }));
      spyOn(history, 'pushState');

      store.state.currentProjectId = 'abcproject';
      store.state.currentBranchId = 'testing';
      store.state.projects.abcproject = {
        branches: {
          master: {
            workingReference: '1',
          },
        },
      };
    });

    it('creates new branch', (done) => {
      store.dispatch('createNewBranch', 'master')
        .then(() => {
          expect(store.state.currentBranchId).toBe('testing');
          expect(service.createBranch).toHaveBeenCalledWith('abcproject', {
            branch: 'master',
            ref: 'testing',
          });

          done();
        })
        .catch(done.fail);
    });
  });
});
