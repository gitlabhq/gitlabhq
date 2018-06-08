import Vue from 'vue';

import AssigneesListContentComponent from 'ee/boards/components/assignees_list/assignees_list_content.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

import { mockAssigneesList } from '../../mock_data';

const createComponent = () => {
  const Component = Vue.extend(AssigneesListContentComponent);

  return mountComponent(Component, {
    assignees: mockAssigneesList,
  });
};

describe('AssigneesListContentComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
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
    it('renders component container element with class `dropdown-content`', () => {
      expect(vm.$el.classList.contains('dropdown-content')).toBe(true);
    });

    it('renders UL parent element as child within container', () => {
      expect(vm.$el.querySelector('ul')).not.toBeNull();
    });
  });
});
