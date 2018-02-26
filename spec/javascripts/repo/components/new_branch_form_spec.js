import Vue from 'vue';
import store from '~/ide/stores';
import newBranchForm from '~/ide/components/new_branch_form.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { resetStore } from '../helpers';

describe('Multi-file editor new branch form', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(newBranchForm);

    vm = createComponentWithStore(Component, store);

    vm.$store.state.currentBranch = 'master';

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
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
    beforeEach(() => {
      spyOn(vm, 'createNewBranch').and.returnValue(Promise.resolve());
    });

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

    it('calls createdNewBranch with branchName', () => {
      vm.branchName = 'testing';

      vm.submitNewBranch();

      expect(vm.createNewBranch).toHaveBeenCalledWith('testing');
    });
  });

  describe('submitNewBranch with error', () => {
    beforeEach(() => {
      spyOn(vm, 'createNewBranch').and.returnValue(Promise.reject({
        json: () => Promise.resolve({
          message: 'error message',
        }),
      }));
    });

    it('sets loading to false', (done) => {
      vm.loading = true;

      vm.submitNewBranch();

      setTimeout(() => {
        expect(vm.loading).toBeFalsy();

        done();
      });
    });

    it('creates flash element', (done) => {
      vm.submitNewBranch();

      setTimeout(() => {
        expect(vm.$el.querySelector('.flash-alert')).not.toBeNull();
        expect(vm.$el.querySelector('.flash-alert').textContent.trim()).toBe('error message');

        done();
      });
    });
  });
});
