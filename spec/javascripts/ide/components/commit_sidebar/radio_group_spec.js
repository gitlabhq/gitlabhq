import Vue from 'vue';
import store from 'ee/ide/stores';
import radioGroup from 'ee/ide/components/commit_sidebar/radio_group.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { resetStore } from 'spec/ide/helpers';

describe('IDE commit sidebar radio group', () => {
  let vm;

  beforeEach((done) => {
    const Component = Vue.extend(radioGroup);

    store.state.commit.commitAction = '2';

    vm = createComponentWithStore(Component, store, {
      value: '1',
      label: 'test',
      checked: true,
    });

    vm.$mount();

    Vue.nextTick(done);
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('uses label if present', () => {
    expect(vm.$el.textContent).toContain('test');
  });

  it('uses slot if label is not present', (done) => {
    vm.$destroy();

    vm = new Vue({
      components: {
        radioGroup,
      },
      store,
      template: `
        <radio-group
          value="1"
        >
          Testing slot
        </radio-group>
      `,
    });

    vm.$mount();

    Vue.nextTick(() => {
      expect(vm.$el.textContent).toContain('Testing slot');

      done();
    });
  });

  it('updates store when changing radio button', (done) => {
    vm.$el.querySelector('input').dispatchEvent(new Event('change'));

    Vue.nextTick(() => {
      expect(store.state.commit.commitAction).toBe('1');

      done();
    });
  });

  it('renders helpText tooltip', (done) => {
    vm.helpText = 'help text';

    Vue.nextTick(() => {
      const help = vm.$el.querySelector('.help-block');

      expect(help).not.toBeNull();
      expect(help.getAttribute('data-original-title')).toBe('help text');

      done();
    });
  });

  describe('with input', () => {
    beforeEach((done) => {
      vm.$destroy();

      const Component = Vue.extend(radioGroup);

      store.state.commit.commitAction = '1';

      vm = createComponentWithStore(Component, store, {
        value: '1',
        label: 'test',
        checked: true,
        showInput: true,
      });

      vm.$mount();

      Vue.nextTick(done);
    });

    it('renders input box when commitAction matches value', () => {
      expect(vm.$el.querySelector('.form-control')).not.toBeNull();
    });

    it('hides input when commitAction doesnt match value', (done) => {
      store.state.commit.commitAction = '2';

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.form-control')).toBeNull();
        done();
      });
    });

    it('updates branch name in store on input', (done) => {
      const input = vm.$el.querySelector('.form-control');
      input.value = 'testing-123';
      input.dispatchEvent(new Event('input'));

      Vue.nextTick(() => {
        expect(store.state.commit.newBranchName).toBe('testing-123');

        done();
      });
    });
  });
});
