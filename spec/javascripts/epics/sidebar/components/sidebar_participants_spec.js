import Vue from 'vue';

import SidebarParticipants from 'ee/epics/sidebar/components/sidebar_participants.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockParticipants } from '../../epic_show/mock_data';

const createComponent = () => {
  const Component = Vue.extend(SidebarParticipants);

  return mountComponent(Component, {
    participants: mockParticipants,
  });
};

describe('SidebarParticipants', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
    describe('onToggleSidebar', () => {
      it('emits `toggleCollapse` event on component', () => {
        spyOn(vm, '$emit');
        vm.onToggleSidebar();
        expect(vm.$emit).toHaveBeenCalledWith('toggleCollapse');
      });
    });
  });

  describe('template', () => {
    it('renders component container element with classes `block participants`', () => {
      expect(vm.$el.classList.contains('block', 'participants')).toBe(true);
    });

    it('renders participants list element', () => {
      expect(vm.$el.querySelector('.participants-list')).not.toBeNull();
      expect(vm.$el.querySelectorAll('.js-participants-author').length).toBe(mockParticipants.length);
    });
  });
});
