import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import frequentItemsListComponent from '~/frequent_items/components/frequent_items_list.vue';
import { mockFrequentProjects } from '../mock_data';

const createComponent = (namespace = 'projects') => {
  const Component = Vue.extend(frequentItemsListComponent);

  return mountComponent(Component, {
    namespace,
    items: mockFrequentProjects,
    isFetchFailed: false,
    hasSearchQuery: false,
    matcher: 'lab',
  });
};

describe('FrequentItemsListComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('isListEmpty', () => {
      it('should return `true` or `false` representing whether if `items` is empty or not with projects', () => {
        vm.items = [];

        expect(vm.isListEmpty).toBe(true);

        vm.items = mockFrequentProjects;

        expect(vm.isListEmpty).toBe(false);
      });
    });

    describe('fetched item messages', () => {
      it('should return appropriate empty list message based on value of `localStorageFailed` prop with projects', () => {
        vm.isFetchFailed = true;

        expect(vm.listEmptyMessage).toBe('This feature requires browser localStorage support');

        vm.isFetchFailed = false;

        expect(vm.listEmptyMessage).toBe('Projects you visit often will appear here');
      });
    });

    describe('searched item messages', () => {
      it('should return appropriate empty list message based on value of `searchFailed` prop with projects', () => {
        vm.hasSearchQuery = true;
        vm.isFetchFailed = true;

        expect(vm.listEmptyMessage).toBe('Something went wrong on our end.');

        vm.isFetchFailed = false;

        expect(vm.listEmptyMessage).toBe('Sorry, no projects matched your search');
      });
    });
  });

  describe('template', () => {
    it('should render component element with list of projects', done => {
      vm.items = mockFrequentProjects;

      Vue.nextTick(() => {
        expect(vm.$el.classList.contains('frequent-items-list-container')).toBe(true);
        expect(vm.$el.querySelectorAll('ul.list-unstyled').length).toBe(1);
        expect(vm.$el.querySelectorAll('li.frequent-items-list-item-container').length).toBe(5);
        done();
      });
    });

    it('should render component element with empty message', done => {
      vm.items = [];

      Vue.nextTick(() => {
        expect(vm.$el.querySelectorAll('li.section-empty').length).toBe(1);
        expect(vm.$el.querySelectorAll('li.frequent-items-list-item-container').length).toBe(0);
        done();
      });
    });
  });
});
