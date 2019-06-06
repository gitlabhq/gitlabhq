import Vue from 'vue';
import store from '~/ide/stores';
import consts from '~/ide/stores/modules/commit/constants';
import NewMergeRequestOption from '~/ide/components/commit_sidebar/new_merge_request_option.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { projectData } from 'spec/ide/mock_data';
import { resetStore } from 'spec/ide/helpers';

describe('create new MR checkbox', () => {
  let vm;
  const createComponent = ({
    hasMR = false,
    commitAction = consts.COMMIT_TO_NEW_BRANCH,
    currentBranchId = 'master',
  } = {}) => {
    const Component = Vue.extend(NewMergeRequestOption);

    vm = createComponentWithStore(Component, store);

    vm.$store.state.currentBranchId = currentBranchId;
    vm.$store.state.currentProjectId = 'abcproject';
    vm.$store.state.commit.commitAction = commitAction;
    Vue.set(vm.$store.state.projects, 'abcproject', { ...projectData });

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

  it('is hidden when an MR already exists and committing to current branch', () => {
    createComponent({
      hasMR: true,
      commitAction: consts.COMMIT_TO_CURRENT_BRANCH,
      currentBranchId: 'feature',
    });

    expect(vm.$el.textContent).toBe('');
  });

  it('does not hide checkbox if MR does not exist', () => {
    createComponent({ hasMR: false });

    expect(vm.$el.querySelector('input[type="checkbox"]').hidden).toBe(false);
  });

  it('does not hide checkbox when creating a new branch', () => {
    createComponent({ commitAction: consts.COMMIT_TO_NEW_BRANCH });

    expect(vm.$el.querySelector('input[type="checkbox"]').hidden).toBe(false);
  });

  it('dispatches toggleShouldCreateMR when clicking checkbox', () => {
    createComponent();
    const el = vm.$el.querySelector('input[type="checkbox"]');
    spyOn(vm.$store, 'dispatch');
    el.dispatchEvent(new Event('change'));

    expect(vm.$store.dispatch.calls.allArgs()).toEqual(
      jasmine.arrayContaining([['commit/toggleShouldCreateMR', jasmine.any(Object)]]),
    );
  });
});
