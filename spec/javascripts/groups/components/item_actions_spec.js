import Vue from 'vue';

import itemActionsComponent from '~/groups/components/item_actions.vue';
import eventHub from '~/groups/event_hub';
import { mockParentGroupItem, mockChildren } from '../mock_data';

import mountComponent from '../../helpers/vue_mount_component_helper';

const createComponent = (group = mockParentGroupItem, parentGroup = mockChildren[0]) => {
  const Component = Vue.extend(itemActionsComponent);

  return mountComponent(Component, {
    group,
    parentGroup,
  });
};

describe('ItemActionsComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('leaveConfirmationMessage', () => {
      it('should return appropriate string for leave group confirmation', () => {
        expect(vm.leaveConfirmationMessage).toBe('Are you sure you want to leave the "platform / hardware" group?');
      });
    });
  });

  describe('methods', () => {
    describe('onLeaveGroup', () => {
      it('should change `modalStatus` prop to `true` which shows confirmation dialog', () => {
        expect(vm.modalStatus).toBeFalsy();
        vm.onLeaveGroup();
        expect(vm.modalStatus).toBeTruthy();
      });
    });

    describe('leaveGroup', () => {
      it('should change `modalStatus` prop to `false` and emit `leaveGroup` event with required params when called with `leaveConfirmed` as `true`', () => {
        spyOn(eventHub, '$emit');
        vm.modalStatus = true;

        vm.leaveGroup();

        expect(vm.modalStatus).toBeFalsy();
        expect(eventHub.$emit).toHaveBeenCalledWith('leaveGroup', vm.group, vm.parentGroup);
      });
    });
  });

  describe('template', () => {
    it('should render component template correctly', () => {
      expect(vm.$el.classList.contains('controls')).toBeTruthy();
    });

    it('should render Edit Group button with correct attribute values', () => {
      const group = Object.assign({}, mockParentGroupItem);
      group.canEdit = true;
      const newVm = createComponent(group);

      const editBtn = newVm.$el.querySelector('a.edit-group');
      expect(editBtn).toBeDefined();
      expect(editBtn.classList.contains('no-expand')).toBeTruthy();
      expect(editBtn.getAttribute('href')).toBe(group.editPath);
      expect(editBtn.getAttribute('aria-label')).toBe('Edit group');
      expect(editBtn.dataset.originalTitle).toBe('Edit group');
      expect(editBtn.querySelector('i.fa.fa-cogs')).toBeDefined();

      newVm.$destroy();
    });

    it('should render Leave Group button with correct attribute values', () => {
      const group = Object.assign({}, mockParentGroupItem);
      group.canLeave = true;
      const newVm = createComponent(group);

      const leaveBtn = newVm.$el.querySelector('a.leave-group');
      expect(leaveBtn).toBeDefined();
      expect(leaveBtn.classList.contains('no-expand')).toBeTruthy();
      expect(leaveBtn.getAttribute('href')).toBe(group.leavePath);
      expect(leaveBtn.getAttribute('aria-label')).toBe('Leave this group');
      expect(leaveBtn.dataset.originalTitle).toBe('Leave this group');
      expect(leaveBtn.querySelector('i.fa.fa-sign-out')).toBeDefined();

      newVm.$destroy();
    });

    it('should show modal dialog when `modalStatus` is set to `true`', () => {
      vm.modalStatus = true;
      const modalDialogEl = vm.$el.querySelector('.modal');
      expect(modalDialogEl).toBeDefined();
      expect(modalDialogEl.querySelector('.modal-title').innerText.trim()).toBe('Are you sure?');
      expect(modalDialogEl.querySelector('.btn.btn-warning').innerText.trim()).toBe('Leave');
    });
  });
});
