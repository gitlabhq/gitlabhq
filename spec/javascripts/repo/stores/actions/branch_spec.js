import * as actions from '~/repo/stores/actions/branch';
import state from '~/repo/stores/state';
import service from '~/repo/services';
import testAction from '../../../helpers/vuex_action_helper';

describe('Multi-file store branch actions', () => {
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('createNewBranch', () => {
    beforeEach(() => {
      spyOn(service, 'createBranch').and.returnValue(Promise.resolve({
        json: () => ({
          name: 'testing',
        }),
      }));
      spyOn(history, 'pushState');

      localState.project.id = 2;
      localState.currentBranch = 'testing';
    });

    it('creates new branch', (done) => {
      testAction(
        actions.createNewBranch,
        'master',
        localState,
        [
          { type: 'SET_CURRENT_BRANCH', payload: 'testing' },
        ],
      ).then(() => {
        expect(service.createBranch).toHaveBeenCalledWith(2, {
          branch: 'master',
          ref: 'testing',
        });
        expect(history.pushState).toHaveBeenCalled();

        done();
      }).catch(done.fail);
    });
  });
});
