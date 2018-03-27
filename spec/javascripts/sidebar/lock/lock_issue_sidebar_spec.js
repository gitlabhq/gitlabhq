import Vue from 'vue';
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
    expect(
      vm1.$el.innerHTML.includes('Edit'),
    ).toBe(true);

    expect(
      vm1.$el.innerHTML.includes('Locked'),
    ).toBe(true);

    expect(
      vm2.$el.innerHTML.includes('Unlocked'),
    ).toBe(true);
  });

  it('displays the edit form when editable', (done) => {
    expect(vm1.isLockDialogOpen).toBe(false);

    vm1.$el.querySelector('.lock-edit').click();

    expect(vm1.isLockDialogOpen).toBe(true);

    vm1.$nextTick(() => {
      expect(
        vm1.$el
          .innerHTML
          .includes('Unlock this issue?'),
      ).toBe(true);

      done();
    });
  });
});
