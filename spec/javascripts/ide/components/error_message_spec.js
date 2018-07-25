import Vue from 'vue';
import store from '~/ide/stores';
import ErrorMessage from '~/ide/components/error_message.vue';
import { createComponentWithStore } from '../../helpers/vue_mount_component_helper';
import { resetStore } from '../helpers';

describe('IDE error message component', () => {
  const Component = Vue.extend(ErrorMessage);
  let vm;

  beforeEach(() => {
    vm = createComponentWithStore(Component, store, {
      message: {
        text: 'error message',
        action: null,
        actionText: null,
      },
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
    resetStore(vm.$store);
  });

  it('renders error message', () => {
    expect(vm.$el.textContent).toContain('error message');
  });

  it('clears error message on click', () => {
    spyOn(vm, 'setErrorMessage');

    vm.$el.click();

    expect(vm.setErrorMessage).toHaveBeenCalledWith(null);
  });

  describe('with action', () => {
    let actionSpy;

    beforeEach(done => {
      actionSpy = jasmine.createSpy('action').and.returnValue(Promise.resolve());

      vm.message.action = actionSpy;
      vm.message.actionText = 'test action';
      vm.message.actionPayload = 'testActionPayload';

      vm.$nextTick(done);
    });

    it('renders action button', () => {
      expect(vm.$el.querySelector('.flash-action')).not.toBe(null);
      expect(vm.$el.textContent).toContain('test action');
    });

    it('does not clear error message on click', () => {
      spyOn(vm, 'setErrorMessage');

      vm.$el.click();

      expect(vm.setErrorMessage).not.toHaveBeenCalled();
    });

    it('dispatches action', done => {
      vm.$el.querySelector('.flash-action').click();

      vm.$nextTick(() => {
        expect(actionSpy).toHaveBeenCalledWith('testActionPayload');

        done();
      });
    });

    it('does not dispatch action when already loading', () => {
      vm.isLoading = true;

      vm.$el.querySelector('.flash-action').click();

      expect(actionSpy).not.toHaveBeenCalledWith();
    });

    it('resets isLoading after click', done => {
      vm.$el.querySelector('.flash-action').click();

      expect(vm.isLoading).toBe(true);

      vm.$nextTick(() => {
        expect(vm.isLoading).toBe(false);

        done();
      });
    });

    it('shows loading icon when isLoading is true', done => {
      expect(vm.$el.querySelector('.loading-container').style.display).not.toBe('');

      vm.isLoading = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.loading-container').style.display).toBe('');

        done();
      });
    });
  });
});
