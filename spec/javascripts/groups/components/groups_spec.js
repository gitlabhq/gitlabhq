import Vue from 'vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import groupsComponent from '~/groups/components/groups.vue';
import groupFolderComponent from '~/groups/components/group_folder.vue';
import groupItemComponent from '~/groups/components/group_item.vue';
import eventHub from '~/groups/event_hub';
import { mockGroups, mockPageInfo } from '../mock_data';

const createComponent = (searchEmpty = false) => {
  const Component = Vue.extend(groupsComponent);

  return mountComponent(Component, {
    groups: mockGroups,
    pageInfo: mockPageInfo,
    searchEmptyMessage: 'No matching results',
    searchEmpty,
  });
};

describe('GroupsComponent', () => {
  let vm;

  beforeEach(done => {
    Vue.component('group-folder', groupFolderComponent);
    Vue.component('group-item', groupItemComponent);

    vm = createComponent();

    Vue.nextTick(() => {
      done();
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
    describe('change', () => {
      it('should emit `fetchPage` event when page is changed via pagination', () => {
        spyOn(eventHub, '$emit').and.stub();

        vm.change(2);

        expect(eventHub.$emit).toHaveBeenCalledWith(
          'fetchPage',
          2,
          jasmine.any(Object),
          jasmine.any(Object),
          jasmine.any(Object),
        );
      });
    });
  });

  describe('template', () => {
    it('should render component template correctly', done => {
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.groups-list-tree-container')).toBeDefined();
        expect(vm.$el.querySelector('.group-list-tree')).toBeDefined();
        expect(vm.$el.querySelector('.gl-pagination')).toBeDefined();
        expect(vm.$el.querySelectorAll('.has-no-search-results').length).toBe(0);
        done();
      });
    });

    it('should render empty search message when `searchEmpty` is `true`', done => {
      vm.searchEmpty = true;
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.has-no-search-results')).toBeDefined();
        done();
      });
    });
  });
});
