import Vue from 'vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { projectData, branches } from 'spec/ide/mock_data';
import { createStore } from '~/ide/stores';
import commitActions from '~/ide/components/commit_sidebar/actions.vue';
import consts from '~/ide/stores/modules/commit/constants';

const ACTION_UPDATE_COMMIT_ACTION = 'commit/updateCommitAction';

describe('IDE commit sidebar actions', () => {
  let store;
  let vm;

  const createComponent = ({ hasMR = false, currentBranchId = 'master' } = {}) => {
    const Component = Vue.extend(commitActions);

    vm = createComponentWithStore(Component, store);

    vm.$store.state.currentBranchId = currentBranchId;
    vm.$store.state.currentProjectId = 'abcproject';

    const proj = { ...projectData };
    proj.branches[currentBranchId] = branches.find(branch => branch.name === currentBranchId);

    Vue.set(vm.$store.state.projects, 'abcproject', proj);

    if (hasMR) {
      vm.$store.state.currentMergeRequestId = '1';
      vm.$store.state.projects[store.state.currentProjectId].mergeRequests[
        store.state.currentMergeRequestId
      ] = { foo: 'bar' };
    }

    vm.$mount();

    return vm;
  };

  beforeEach(() => {
    store = createStore();
    spyOn(store, 'dispatch');
  });

  afterEach(() => {
    vm.$destroy();
    vm = null;
  });

  it('renders 2 groups', () => {
    createComponent();

    expect(vm.$el.querySelectorAll('input[type="radio"]').length).toBe(2);
  });

  it('renders current branch text', () => {
    createComponent();

    expect(vm.$el.textContent).toContain('Commit to master branch');
  });

  it('hides merge request option when project merge requests are disabled', done => {
    createComponent({ mergeRequestsEnabled: false });

    vm.$nextTick(() => {
      expect(vm.$el.querySelectorAll('input[type="radio"]').length).toBe(2);
      expect(vm.$el.textContent).not.toContain('Create a new branch and merge request');

      done();
    });
  });

  describe('commitToCurrentBranchText', () => {
    it('escapes current branch', () => {
      const injectedSrc = '<img src="x" />';
      createComponent({ currentBranchId: injectedSrc });

      expect(vm.commitToCurrentBranchText).not.toContain(injectedSrc);
    });
  });

  describe('updateSelectedCommitAction', () => {
    it('does not return anything if currentBranch does not exist', () => {
      createComponent({ currentBranchId: null });

      expect(vm.$store.dispatch).not.toHaveBeenCalled();
    });

    it('calls again after staged changes', done => {
      createComponent({ currentBranchId: null });

      vm.$store.state.currentBranchId = 'master';
      vm.$store.state.changedFiles.push({});
      vm.$store.state.stagedFiles.push({});

      vm.$nextTick()
        .then(() => {
          expect(vm.$store.dispatch).toHaveBeenCalledWith(
            ACTION_UPDATE_COMMIT_ACTION,
            jasmine.anything(),
          );
        })
        .then(done)
        .catch(done.fail);
    });

    describe('default branch', () => {
      it('dispatches correct action for default branch', () => {
        createComponent({
          currentBranchId: 'master',
        });

        expect(vm.$store.dispatch).toHaveBeenCalledTimes(1);
        expect(vm.$store.dispatch).toHaveBeenCalledWith(
          ACTION_UPDATE_COMMIT_ACTION,
          consts.COMMIT_TO_NEW_BRANCH,
        );
      });
    });

    describe('protected branch', () => {
      describe('with write access', () => {
        it('dispatches correct action when MR exists', () => {
          createComponent({
            hasMR: true,
            currentBranchId: 'protected/access',
          });

          expect(vm.$store.dispatch).toHaveBeenCalledWith(
            ACTION_UPDATE_COMMIT_ACTION,
            consts.COMMIT_TO_CURRENT_BRANCH,
          );
        });

        it('dispatches correct action when MR does not exists', () => {
          createComponent({
            hasMR: false,
            currentBranchId: 'protected/access',
          });

          expect(vm.$store.dispatch).toHaveBeenCalledWith(
            ACTION_UPDATE_COMMIT_ACTION,
            consts.COMMIT_TO_CURRENT_BRANCH,
          );
        });
      });

      describe('without write access', () => {
        it('dispatches correct action when MR exists', () => {
          createComponent({
            hasMR: true,
            currentBranchId: 'protected/no-access',
          });

          expect(vm.$store.dispatch).toHaveBeenCalledWith(
            ACTION_UPDATE_COMMIT_ACTION,
            consts.COMMIT_TO_NEW_BRANCH,
          );
        });

        it('dispatches correct action when MR does not exists', () => {
          createComponent({
            hasMR: false,
            currentBranchId: 'protected/no-access',
          });

          expect(vm.$store.dispatch).toHaveBeenCalledWith(
            ACTION_UPDATE_COMMIT_ACTION,
            consts.COMMIT_TO_NEW_BRANCH,
          );
        });
      });
    });

    describe('regular branch', () => {
      describe('with write access', () => {
        it('dispatches correct action when MR exists', () => {
          createComponent({
            hasMR: true,
            currentBranchId: 'regular',
          });

          expect(vm.$store.dispatch).toHaveBeenCalledWith(
            ACTION_UPDATE_COMMIT_ACTION,
            consts.COMMIT_TO_CURRENT_BRANCH,
          );
        });

        it('dispatches correct action when MR does not exists', () => {
          createComponent({
            hasMR: false,
            currentBranchId: 'regular',
          });

          expect(vm.$store.dispatch).toHaveBeenCalledWith(
            ACTION_UPDATE_COMMIT_ACTION,
            consts.COMMIT_TO_CURRENT_BRANCH,
          );
        });
      });

      describe('without write access', () => {
        it('dispatches correct action when MR exists', () => {
          createComponent({
            hasMR: true,
            currentBranchId: 'regular/no-access',
          });

          expect(vm.$store.dispatch).toHaveBeenCalledWith(
            ACTION_UPDATE_COMMIT_ACTION,
            consts.COMMIT_TO_NEW_BRANCH,
          );
        });

        it('dispatches correct action when MR does not exists', () => {
          createComponent({
            hasMR: false,
            currentBranchId: 'regular/no-access',
          });

          expect(vm.$store.dispatch).toHaveBeenCalledWith(
            ACTION_UPDATE_COMMIT_ACTION,
            consts.COMMIT_TO_NEW_BRANCH,
          );
        });
      });
    });
  });
});
