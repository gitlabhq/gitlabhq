import Vue from 'vue';
import store from '~/ide/stores';
import ideSidebar from '~/ide/components/ide_side_bar.vue';
import { ActivityBarViews } from '~/ide/stores/state';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { resetStore } from '../helpers';
import { projectData } from '../mock_data';

describe('IdeSidebar', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(ideSidebar);

    store.state.currentProjectId = 'abcproject';
    store.state.projects.abcproject = projectData;

    vm = createComponentWithStore(Component, store).$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders a sidebar', () => {
    expect(vm.$el.querySelector('.multi-file-commit-panel-inner')).not.toBeNull();
  });

  it('renders loading icon component', done => {
    vm.$store.state.loading = true;

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.multi-file-loading-container')).not.toBeNull();
      expect(vm.$el.querySelectorAll('.multi-file-loading-container').length).toBe(3);

      done();
    });
  });

  describe('activityBarComponent', () => {
    it('renders tree component', () => {
      expect(vm.$el.querySelector('.ide-file-list')).not.toBeNull();
    });

    it('renders commit component', done => {
      vm.$store.state.currentActivityView = ActivityBarViews.commit;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.multi-file-commit-panel-section')).not.toBeNull();

        done();
      });
    });
  });
});
