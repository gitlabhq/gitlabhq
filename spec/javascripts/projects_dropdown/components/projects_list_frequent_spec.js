import Vue from 'vue';

import projectsListFrequentComponent from '~/projects_dropdown/components/projects_list_frequent.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockFrequents } from '../mock_data';

const createComponent = () => {
  const Component = Vue.extend(projectsListFrequentComponent);

  return mountComponent(Component, {
    projects: mockFrequents,
    localStorageFailed: false,
  });
};

describe('ProjectsListFrequentComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('isListEmpty', () => {
      it('should return `true` or `false` representing whether if `projects` is empty of not', () => {
        vm.projects = [];
        expect(vm.isListEmpty).toBeTruthy();

        vm.projects = mockFrequents;
        expect(vm.isListEmpty).toBeFalsy();
      });
    });

    describe('listEmptyMessage', () => {
      it('should return appropriate empty list message based on value of `localStorageFailed` prop', () => {
        vm.localStorageFailed = true;
        expect(vm.listEmptyMessage).toBe('This feature requires browser localStorage support');

        vm.localStorageFailed = false;
        expect(vm.listEmptyMessage).toBe('Projects you visit often will appear here');
      });
    });
  });

  describe('template', () => {
    it('should render component element with list of projects', (done) => {
      vm.projects = mockFrequents;

      Vue.nextTick(() => {
        expect(vm.$el.classList.contains('projects-list-frequent-container')).toBeTruthy();
        expect(vm.$el.querySelectorAll('ul.list-unstyled').length).toBe(1);
        expect(vm.$el.querySelectorAll('li.projects-list-item-container').length).toBe(5);
        done();
      });
    });

    it('should render component element with empty message', (done) => {
      vm.projects = [];

      Vue.nextTick(() => {
        expect(vm.$el.querySelectorAll('li.section-empty').length).toBe(1);
        expect(vm.$el.querySelectorAll('li.projects-list-item-container').length).toBe(0);
        done();
      });
    });
  });
});
