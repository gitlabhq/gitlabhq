import Vue from 'vue';
import navigationTabs from '~/pipelines/components/navigation_tabs.vue';
import mountComponent from '../helpers/vue_mount_component_helper';

describe('navigation tabs pipeline component', () => {
  let vm;
  let Component;
  let data;

  beforeEach(() => {
    data = {
      scope: 'all',
      count: {
        all: 16,
        running: 1,
        pending: 10,
        finished: 0,
      },
      paths: {
        allPath: '/gitlab-org/gitlab-ce/pipelines',
        pendingPath: '/gitlab-org/gitlab-ce/pipelines?scope=pending',
        finishedPath: '/gitlab-org/gitlab-ce/pipelines?scope=finished',
        runningPath: '/gitlab-org/gitlab-ce/pipelines?scope=running',
        branchesPath: '/gitlab-org/gitlab-ce/pipelines?scope=branches',
        tagsPath: '/gitlab-org/gitlab-ce/pipelines?scope=tags',
      },
    };

    Component = Vue.extend(navigationTabs);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render tabs with correct paths', () => {
    vm = mountComponent(Component, data);

    // All
    const allTab = vm.$el.querySelector('.js-pipelines-tab-all a');
    expect(allTab.textContent.trim()).toContain('All');
    expect(allTab.getAttribute('href')).toEqual(data.paths.allPath);

    // Pending
    const pendingTab = vm.$el.querySelector('.js-pipelines-tab-pending a');
    expect(pendingTab.textContent.trim()).toContain('Pending');
    expect(pendingTab.getAttribute('href')).toEqual(data.paths.pendingPath);

    // Running
    const runningTab = vm.$el.querySelector('.js-pipelines-tab-running a');
    expect(runningTab.textContent.trim()).toContain('Running');
    expect(runningTab.getAttribute('href')).toEqual(data.paths.runningPath);

    // Finished
    const finishedTab = vm.$el.querySelector('.js-pipelines-tab-finished a');
    expect(finishedTab.textContent.trim()).toContain('Finished');
    expect(finishedTab.getAttribute('href')).toEqual(data.paths.finishedPath);

    // Branches
    const branchesTab = vm.$el.querySelector('.js-pipelines-tab-branches a');
    expect(branchesTab.textContent.trim()).toContain('Branches');

    // Tags
    const tagsTab = vm.$el.querySelector('.js-pipelines-tab-tags a');
    expect(tagsTab.textContent.trim()).toContain('Tags');
  });

  describe('scope', () => {
    it('should render scope provided as active tab', () => {
      vm = mountComponent(Component, data);
      expect(vm.$el.querySelector('.js-pipelines-tab-all').className).toContain('active');
    });
  });

  describe('badges', () => {
    it('should render provided number', () => {
      vm = mountComponent(Component, data);
      // All
      expect(
        vm.$el.querySelector('.js-totalbuilds-count').textContent.trim(),
      ).toContain(data.count.all);

      // Pending
      expect(
        vm.$el.querySelector('.js-pipelines-tab-pending .badge').textContent.trim(),
      ).toContain(data.count.pending);

      // Running
      expect(
        vm.$el.querySelector('.js-pipelines-tab-running .badge').textContent.trim(),
      ).toContain(data.count.running);

      // Finished
      expect(
        vm.$el.querySelector('.js-pipelines-tab-finished .badge').textContent.trim(),
      ).toContain(data.count.finished);
    });

    it('should not render badge when number is undefined', () => {
      vm = mountComponent(Component, {
        scope: 'all',
        paths: {},
        count: {},
      });

       // All
      expect(
        vm.$el.querySelector('.js-totalbuilds-count'),
      ).toEqual(null);

      // Pending
      expect(
        vm.$el.querySelector('.js-pipelines-tab-pending .badge'),
      ).toEqual(null);

      // Running
      expect(
        vm.$el.querySelector('.js-pipelines-tab-running .badge'),
      ).toEqual(null);

      // Finished
      expect(
        vm.$el.querySelector('.js-pipelines-tab-finished .badge'),
      ).toEqual(null);
    });
  });
});
