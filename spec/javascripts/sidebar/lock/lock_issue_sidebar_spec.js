import Vue from 'vue';
import { mockTracking, triggerEvent } from 'spec/helpers/tracking_helper';
import lockIssueSidebar from '~/sidebar/components/lock/lock_issue_sidebar.vue';

describe('LockIssueSidebar', () => {
  let vm1;
  let vm2;

  beforeEach(() => {
    const Component = Vue.extend(lockIssueSidebar);

    const mediator = {
      service: {
        update: Promise.resolve(true),
      },

      store: {
        isLockDialogOpen: false,
      },
    };

    vm1 = new Component({
      propsData: {
        isLocked: true,
        isEditable: true,
        mediator,
        issuableType: 'issue',
      },
    }).$mount();

    vm2 = new Component({
      propsData: {
        isLocked: false,
        isEditable: false,
        mediator,
        issuableType: 'merge_request',
      },
    }).$mount();
  });

  it('shows if locked and/or editable', () => {
    expect(vm1.$el.innerHTML.includes('Edit')).toBe(true);

    expect(vm1.$el.innerHTML.includes('Locked')).toBe(true);

    expect(vm2.$el.innerHTML.includes('Unlocked')).toBe(true);
  });

  it('displays the edit form when editable', done => {
    expect(vm1.isLockDialogOpen).toBe(false);

    vm1.$el.querySelector('.lock-edit').click();

    expect(vm1.isLockDialogOpen).toBe(true);

    vm1.$nextTick(() => {
      expect(vm1.$el.innerHTML.includes('Unlock this issue?')).toBe(true);

      done();
    });
  });

  it('tracks an event when "Edit" is clicked', () => {
    const spy = mockTracking('_category_', vm1.$el, spyOn);
    triggerEvent('.lock-edit');

    expect(spy).toHaveBeenCalledWith('_category_', 'click_edit_button', {
      label: 'right_sidebar',
      property: 'lock_issue',
    });
  });

  it('displays the edit form when opened from collapsed state', done => {
    expect(vm1.isLockDialogOpen).toBe(false);

    vm1.$el.querySelector('.sidebar-collapsed-icon').click();

    expect(vm1.isLockDialogOpen).toBe(true);

    setTimeout(() => {
      expect(vm1.$el.innerHTML.includes('Unlock this issue?')).toBe(true);

      done();
    });
  });
});
