import Vue from 'vue';
import store from '~/ide/stores';
import listCollapsed from '~/ide/components/commit_sidebar/list_collapsed.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { file } from '../../helpers';

describe('Multi-file editor commit sidebar list collapsed', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(listCollapsed);

    vm = createComponentWithStore(Component, store);

    vm.$store.state.openFiles.push(file(), file());
    vm.$store.state.openFiles[0].tempFile = true;
    vm.$store.state.openFiles.forEach((f) => {
      Object.assign(f, {
        changed: true,
      });
    });

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders added & modified files count', () => {
    expect(vm.$el.textContent.replace(/\s+/g, ' ').trim()).toBe('1 1');
  });
});
