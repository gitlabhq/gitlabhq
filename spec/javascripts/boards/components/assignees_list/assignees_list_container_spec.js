import Vue from 'vue';

import AssigneesListContainerComponent from 'ee/boards/components/assignees_list/assignees_list_container.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

import { mockAssigneesList } from '../../mock_data';

const createComponent = () => {
  const Component = Vue.extend(AssigneesListContainerComponent);

  return mountComponent(Component, {
    loading: false,
    assignees: mockAssigneesList,
  });
};

describe('AssigneesListContainerComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('filteredAssignees', () => {
      it('returns assignees list as it is when `query` is empty', () => {
        vm.query = '';
        expect(vm.filteredAssignees.length).toBe(mockAssigneesList.length);
      });

      it('returns filtered assignees list as it is when `query` has name', () => {
        const assignee = mockAssigneesList[0];

        vm.query = assignee.name;
        expect(vm.filteredAssignees.length).toBe(1);
        expect(vm.filteredAssignees[0].name).toBe(assignee.name);
      });

      it('returns filtered assignees list as it is when `query` has username', () => {
        const assignee = mockAssigneesList[0];

        vm.query = assignee.username;
        expect(vm.filteredAssignees.length).toBe(1);
        expect(vm.filteredAssignees[0].username).toBe(assignee.username);
      });
    });
  });

  describe('methods', () => {
    describe('handleSearch', () => {
      it('sets value of param `query` to component prop `query`', () => {
        const query = 'foobar';
        vm.handleSearch(query);
        expect(vm.query).toBe(query);
      });
    });

    describe('handleItemClick', () => {
      it('emits `onItemSelect` event on component and sends `assignee` as event param', () => {
        spyOn(vm, '$emit');
        const assignee = mockAssigneesList[0];

        vm.handleItemClick(assignee);
        expect(vm.$emit).toHaveBeenCalledWith('onItemSelect', assignee);
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `dropdown-assignees-list`', () => {
      expect(vm.$el.classList.contains('dropdown-assignees-list')).toBe(true);
    });

    it('renders loading animation when prop `loading` is true', (done) => {
      vm.loading = true;
      Vue.nextTick()
        .then(() => {
          expect(vm.$el.querySelector('.dropdown-loading')).not.toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders dropdown body elements', () => {
      expect(vm.$el.querySelector('.dropdown-input')).not.toBeNull();
      expect(vm.$el.querySelector('.dropdown-content')).not.toBeNull();
    });
  });
});
