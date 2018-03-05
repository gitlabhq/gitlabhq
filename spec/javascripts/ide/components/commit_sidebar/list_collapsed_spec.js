import Vue from 'vue';
import store from 'ee/ide/stores';
import listCollapsed from 'ee/ide/components/commit_sidebar/list_collapsed.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { file } from '../../helpers';

describe('Multi-file editor commit sidebar list collapsed', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(listCollapsed);

    vm = createComponentWithStore(Component, store);

    vm.$store.state.changedFiles.push(file('file1'), file('file2'));
    vm.$store.state.changedFiles[0].tempFile = true;

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders added & modified files count', () => {
    expect(vm.$el.textContent.replace(/\s+/g, ' ').trim()).toBe('1 1');
  });
});
