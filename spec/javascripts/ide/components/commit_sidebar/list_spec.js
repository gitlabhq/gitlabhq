import Vue from 'vue';
import store from 'ee/ide/stores';
import commitSidebarList from 'ee/ide/components/commit_sidebar/list.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { file } from '../../helpers';

describe('Multi-file editor commit sidebar list', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(commitSidebarList);

    vm = createComponentWithStore(Component, store, {
      title: 'Staged',
      fileList: [],
    });

    vm.$store.state.rightPanelCollapsed = false;

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('with a list of files', () => {
    beforeEach((done) => {
      const f = file('file name');
      f.changed = true;
      vm.fileList.push(f);

      Vue.nextTick(done);
    });

    it('renders list', () => {
      expect(vm.$el.querySelectorAll('li').length).toBe(1);
    });
  });

  describe('collapsed', () => {
    beforeEach((done) => {
      vm.$store.state.rightPanelCollapsed = true;

      Vue.nextTick(done);
    });

    it('hides list', () => {
      expect(vm.$el.querySelector('.list-unstyled')).toBeNull();
      expect(vm.$el.querySelector('.help-block')).toBeNull();
    });
  });
});
