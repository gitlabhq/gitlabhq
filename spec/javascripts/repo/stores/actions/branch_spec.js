import store from '~/repo/stores';
import service from '~/repo/services';
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

      store.state.project.id = 2;
      store.state.currentBranch = 'testing';
    });

    it('creates new branch', (done) => {
      store.dispatch('createNewBranch', 'master')
        .then(() => {
          expect(store.state.currentBranch).toBe('testing');
          expect(service.createBranch).toHaveBeenCalledWith(2, {
            branch: 'master',
            ref: 'testing',
          });
          expect(history.pushState).toHaveBeenCalled();

          done();
        })
        .catch(done.fail);
    });
  });
});
