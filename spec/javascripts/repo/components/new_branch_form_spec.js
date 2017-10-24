import Vue from 'vue';
import newBranchForm from '~/repo/components/new_branch_form.vue';
import eventHub from '~/repo/event_hub';
import RepoStore from '~/repo/stores/repo_store';
import createComponent from '../../helpers/vue_mount_component_helper';

describe('Multi-file editor new branch form', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(newBranchForm);

    RepoStore.currentBranch = 'master';

    vm = createComponent(Component, {
      currentBranch: RepoStore.currentBranch,
    });
  });

  afterEach(() => {
    vm.$destroy();

    RepoStore.currentBranch = '';
  });

  describe('template', () => {
    it('renders submit as disabled', () => {
      expect(vm.$el.querySelector('.btn').getAttribute('disabled')).toBe('disabled');
    });

    it('enables the submit button when branch is not empty', (done) => {
      vm.branchName = 'testing';

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.btn').getAttribute('disabled')).toBeNull();

        done();
      });
    });

    it('displays current branch creating from', (done) => {
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('p').textContent.replace(/\s+/g, ' ').trim()).toBe('Create from: master');

        done();
      });
    });
  });

  describe('submitNewBranch', () => {
    it('sets to loading', () => {
      vm.submitNewBranch();

      expect(vm.loading).toBeTruthy();
    });

    it('hides current flash element', (done) => {
      vm.$refs.flashContainer.innerHTML = '<div class="flash-alert"></div>';

      vm.submitNewBranch();

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.flash-alert')).toBeNull();

        done();
      });
    });

    it('emits an event with branchName', () => {
      spyOn(eventHub, '$emit');

      vm.branchName = 'testing';

      vm.submitNewBranch();

      expect(eventHub.$emit).toHaveBeenCalledWith('createNewBranch', 'testing');
    });
  });

  describe('showErrorMessage', () => {
    it('sets loading to false', () => {
      vm.loading = true;

      vm.showErrorMessage();

      expect(vm.loading).toBeFalsy();
    });

    it('creates flash element', () => {
      vm.showErrorMessage('error message');

      expect(vm.$el.querySelector('.flash-alert')).not.toBeNull();
      expect(vm.$el.querySelector('.flash-alert').textContent.trim()).toBe('error message');
    });
  });

  describe('createdNewBranch', () => {
    it('set loading to false', () => {
      vm.loading = true;

      vm.createdNewBranch();

      expect(vm.loading).toBeFalsy();
    });

    it('resets branch name', () => {
      vm.branchName = 'testing';

      vm.createdNewBranch();

      expect(vm.branchName).toBe('');
    });

    it('sets the dropdown toggle text', () => {
      vm.dropdownText = document.createElement('span');

      vm.createdNewBranch('branch name');

      expect(vm.dropdownText.textContent).toBe('branch name');
    });
  });
});
