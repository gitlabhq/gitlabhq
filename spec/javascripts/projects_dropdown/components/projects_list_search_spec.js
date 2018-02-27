import Vue from 'vue';

import projectsListSearchComponent from '~/projects_dropdown/components/projects_list_search.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockProject } from '../mock_data';

const createComponent = () => {
  const Component = Vue.extend(projectsListSearchComponent);

  return mountComponent(Component, {
    projects: [mockProject],
    matcher: 'lab',
    searchFailed: false,
  });
};

describe('ProjectsListSearchComponent', () => {
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

        vm.projects = [mockProject];
        expect(vm.isListEmpty).toBeFalsy();
      });
    });

    describe('listEmptyMessage', () => {
      it('should return appropriate empty list message based on value of `searchFailed` prop', () => {
        vm.searchFailed = true;
        expect(vm.listEmptyMessage).toBe('Something went wrong on our end.');

        vm.searchFailed = false;
        expect(vm.listEmptyMessage).toBe('Sorry, no projects matched your search');
      });
    });
  });

  describe('template', () => {
    it('should render component element with list of projects', (done) => {
      vm.projects = [mockProject];

      Vue.nextTick(() => {
        expect(vm.$el.classList.contains('projects-list-search-container')).toBeTruthy();
        expect(vm.$el.querySelectorAll('ul.list-unstyled').length).toBe(1);
        expect(vm.$el.querySelectorAll('li.projects-list-item-container').length).toBe(1);
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

    it('should render component element with failure message', (done) => {
      vm.searchFailed = true;
      vm.projects = [];

      Vue.nextTick(() => {
        expect(vm.$el.querySelectorAll('li.section-empty.section-failure').length).toBe(1);
        expect(vm.$el.querySelectorAll('li.projects-list-item-container').length).toBe(0);
        done();
      });
    });
  });
});
