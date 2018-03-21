import Vue from 'vue';
import store from '~/ide/stores';
import stageButton from '~/ide/components/commit_sidebar/stage_button.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { file, resetStore } from '../../helpers';

describe('IDE stage file button', () => {
  let vm;
  let f;

  beforeEach(() => {
    const Component = Vue.extend(stageButton);
    f = file();

    vm = createComponentWithStore(Component, store, {
      file: f,
    });

    spyOn(vm, 'stageChange');
    spyOn(vm, 'discardFileChanges');

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders button to discard & stage', () => {
    expect(vm.$el.querySelectorAll('.btn').length).toBe(2);
  });

  it('calls store with stage button', () => {
    vm.$el.querySelectorAll('.btn')[0].click();

    expect(vm.stageChange).toHaveBeenCalledWith(f);
  });

  it('calls store with discard button', () => {
    vm.$el.querySelectorAll('.btn')[1].click();

    expect(vm.discardFileChanges).toHaveBeenCalledWith(f);
  });
});
