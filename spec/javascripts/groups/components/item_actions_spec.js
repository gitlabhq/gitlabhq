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
      it('should change `dialogStatus` prop to `true` which shows confirmation dialog', () => {
        expect(vm.dialogStatus).toBeFalsy();
        vm.onLeaveGroup();
        expect(vm.dialogStatus).toBeTruthy();
      });
    });

    describe('leaveGroup', () => {
      it('should change `dialogStatus` prop to `false` and emit `leaveGroup` event with required params when called with `leaveConfirmed` as `true`', () => {
        spyOn(eventHub, '$emit');
        vm.dialogStatus = true;
        vm.leaveGroup(true);
        expect(vm.dialogStatus).toBeFalsy();
        expect(eventHub.$emit).toHaveBeenCalledWith('leaveGroup', vm.group, vm.parentGroup);
      });

      it('should change `dialogStatus` prop to `false` and should NOT emit `leaveGroup` event when called with `leaveConfirmed` as `false`', () => {
        spyOn(eventHub, '$emit');
        vm.dialogStatus = true;
        vm.leaveGroup(false);
        expect(vm.dialogStatus).toBeFalsy();
        expect(eventHub.$emit).not.toHaveBeenCalled();
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

    it('should show modal dialog when `dialogStatus` is set to `true`', () => {
      vm.dialogStatus = true;
      const modalDialogEl = vm.$el.querySelector('.modal.popup-dialog');
      expect(modalDialogEl).toBeDefined();
      expect(modalDialogEl.querySelector('.modal-title').innerText.trim()).toBe('Are you sure?');
      expect(modalDialogEl.querySelector('.btn.btn-warning').innerText.trim()).toBe('Leave');
    });
  });
});
