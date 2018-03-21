import Vue from 'vue';
import store from '~/ide/stores';
import commitSidebarList from '~/ide/components/commit_sidebar/list.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { file, resetStore } from '../../helpers';

describe('Multi-file editor commit sidebar list', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(commitSidebarList);

    vm = createComponentWithStore(Component, store, {
      title: 'Staged',
      fileList: [],
      icon: 'staged',
      action: 'stageAllChanges',
      actionBtnText: 'stage all',
      itemActionComponent: 'stage-button',
    });

    vm.$store.state.rightPanelCollapsed = false;

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  describe('with a list of files', () => {
    beforeEach(done => {
      const f = file('file name');
      f.changed = true;
      vm.fileList.push(f);

      Vue.nextTick(done);
    });

    it('renders list', () => {
      expect(vm.$el.querySelectorAll('li').length).toBe(1);
    });
  });

  describe('empty files array', () => {
    it('renders no changes text when empty', () => {
      expect(vm.$el.textContent).toContain('No changes');
    });
  });

  describe('collapsed', () => {
    beforeEach(done => {
      vm.$store.state.rightPanelCollapsed = true;

      Vue.nextTick(done);
    });

    it('hides list', () => {
      expect(vm.$el.querySelector('.list-unstyled')).toBeNull();
      expect(vm.$el.querySelector('.help-block')).toBeNull();
    });
  });

  describe('with toggle', () => {
    beforeEach(done => {
      spyOn(vm, 'toggleRightPanelCollapsed');

      vm.showToggle = true;

      Vue.nextTick(done);
    });

    it('calls setPanelCollapsedStatus when clickin toggle', () => {
      vm.$el.querySelector('.multi-file-commit-panel-collapse-btn').click();

      expect(vm.toggleRightPanelCollapsed).toHaveBeenCalled();
    });
  });

  describe('action button', () => {
    beforeEach(() => {
      spyOn(vm, 'stageAllChanges');
    });

    it('calls store action when clicked', () => {
      vm.$el.querySelector('.ide-staged-action-btn').click();

      expect(vm.stageAllChanges).toHaveBeenCalled();
    });
  });
});
