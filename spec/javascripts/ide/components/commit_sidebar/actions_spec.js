import Vue from 'vue';
import store from '~/ide/stores';
import commitActions from '~/ide/components/commit_sidebar/actions.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { resetStore } from 'spec/ide/helpers';
import { projectData } from 'spec/ide/mock_data';

describe('IDE commit sidebar actions', () => {
  let vm;

  beforeEach(done => {
    const Component = Vue.extend(commitActions);

    vm = createComponentWithStore(Component, store);

    vm.$store.state.currentBranchId = 'master';
    vm.$store.state.currentProjectId = 'abcproject';
    Vue.set(vm.$store.state.projects, 'abcproject', { ...projectData });

    vm.$mount();

    Vue.nextTick(done);
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders 3 groups', () => {
    expect(vm.$el.querySelectorAll('input[type="radio"]').length).toBe(3);
  });

  it('renders current branch text', () => {
    expect(vm.$el.textContent).toContain('Commit to master branch');
  });

  it('hides merge request option when project merge requests are disabled', done => {
    vm.$store.state.projects.abcproject.merge_requests_enabled = false;

    vm.$nextTick(() => {
      expect(vm.$el.querySelectorAll('input[type="radio"]').length).toBe(2);
      expect(vm.$el.textContent).not.toContain('Create a new branch and merge request');

      done();
    });
  });

  describe('commitToCurrentBranchText', () => {
    it('escapes current branch', () => {
      vm.$store.state.currentBranchId = '<img src="x" />';

      expect(vm.commitToCurrentBranchText).not.toContain('<img src="x" />');
    });
  });
});
