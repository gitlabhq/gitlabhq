import Vue from 'vue';
import store from '~/ide/stores';
import consts from '~/ide/stores/modules/commit/constants';
import commitActions from '~/ide/components/commit_sidebar/actions.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { resetStore } from 'spec/ide/helpers';
import { projectData } from 'spec/ide/mock_data';

describe('IDE commit sidebar actions', () => {
  let vm;
  const createComponent = ({
    hasMR = false,
    commitAction = consts.COMMIT_TO_NEW_BRANCH,
    mergeRequestsEnabled = true,
    currentBranchId = 'master',
    shouldCreateMR = false,
  } = {}) => {
    const Component = Vue.extend(commitActions);

    vm = createComponentWithStore(Component, store);

    vm.$store.state.currentBranchId = currentBranchId;
    vm.$store.state.currentProjectId = 'abcproject';
    vm.$store.state.commit.commitAction = commitAction;
    Vue.set(vm.$store.state.projects, 'abcproject', { ...projectData });
    vm.$store.state.projects.abcproject.merge_requests_enabled = mergeRequestsEnabled;
    vm.$store.state.commit.shouldCreateMR = shouldCreateMR;

    if (hasMR) {
      vm.$store.state.currentMergeRequestId = '1';
      vm.$store.state.projects[store.state.currentProjectId].mergeRequests[
        store.state.currentMergeRequestId
      ] = { foo: 'bar' };
    }

    return vm.$mount();
  };

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
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

  describe('create new MR checkbox', () => {
    it('disables `createMR` button when an MR already exists and committing to current branch', () => {
      createComponent({ hasMR: true, commitAction: consts.COMMIT_TO_CURRENT_BRANCH });

      expect(vm.$el.querySelector('input[type="checkbox"]').disabled).toBe(true);
    });

    it('does not disable checkbox if MR does not exist', () => {
      createComponent({ hasMR: false });

      expect(vm.$el.querySelector('input[type="checkbox"]').disabled).toBe(false);
    });

    it('does not disable checkbox when creating a new branch', () => {
      createComponent({ commitAction: consts.COMMIT_TO_NEW_BRANCH });

      expect(vm.$el.querySelector('input[type="checkbox"]').disabled).toBe(false);
    });

    it('toggles off new MR when switching back to commit to current branch and MR exists', () => {
      createComponent({
        commitAction: consts.COMMIT_TO_NEW_BRANCH,
        shouldCreateMR: true,
      });
      const currentBranchRadio = vm.$el.querySelector(
        `input[value="${consts.COMMIT_TO_CURRENT_BRANCH}"`,
      );
      currentBranchRadio.click();

      vm.$nextTick(() => {
        expect(vm.$store.state.commit.shouldCreateMR).toBe(false);
      });
    });

    it('toggles `shouldCreateMR` when clicking checkbox', () => {
      createComponent();
      const el = vm.$el.querySelector('input[type="checkbox"]');
      el.dispatchEvent(new Event('change'));

      expect(vm.$store.state.commit.shouldCreateMR).toBe(true);
    });
  });
});
