import Vue from 'vue';
import store from '~/repo/stores';
import commitSidebarList from '~/repo/components/commit_sidebar/list.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { file } from '../../helpers';

describe('Multi-file editor commit sidebar list', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(commitSidebarList);

    vm = createComponentWithStore(Component, store, {
      title: 'Staged',
      fileList: [],
      collapsed: false,
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('empty file list', () => {
    it('renders no changes text', () => {
      expect(vm.$el.querySelector('.help-block').textContent.trim()).toBe('No changes');
    });
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
      vm.collapsed = true;

      Vue.nextTick(done);
    });

    it('adds collapsed class', () => {
      expect(vm.$el.querySelector('.is-collapsed')).not.toBeNull();
    });

    it('hides list', () => {
      expect(vm.$el.querySelector('.list-unstyled')).toBeNull();
      expect(vm.$el.querySelector('.help-block')).toBeNull();
    });

    it('hides collapse button', () => {
      expect(vm.$el.querySelector('.multi-file-commit-panel-collapse-btn')).toBeNull();
    });
  });

  it('clicking toggle collapse button emits toggle event', () => {
    spyOn(vm, '$emit');

    vm.$el.querySelector('.multi-file-commit-panel-collapse-btn').click();

    expect(vm.$emit).toHaveBeenCalledWith('toggleCollapsed');
  });
});
