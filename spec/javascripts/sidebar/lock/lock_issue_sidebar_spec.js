import Vue from 'vue';
import lockIssueSidebar from '~/sidebar/components/lock/lock_issue_sidebar.vue';

describe('LockIssueSidebar', () => {
  let vm1;
  let vm2;

  beforeEach(() => {
    const Component = Vue.extend(lockIssueSidebar);
    const service = {
      update: () => new Promise((resolve, reject) => {
        resolve(true);
        reject('failed!');
      }),
    };

    vm1 = new Component({
      propsData: {
        isLocked: true,
        isEditable: true,
        service,
        issuableType: 'issue',
      },
    }).$mount();

    vm2 = new Component({
      propsData: {
        isLocked: false,
        isEditable: false,
        service,
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
    expect(vm1.isEditing).toBe(false);

    vm1.$el.querySelector('.lock-edit').click();

    expect(vm1.isEditing).toBe(true);

    setTimeout(() => {
      expect(
        vm1.$el
          .innerHTML
          .includes('Unlock this issue?'),
      ).toBe(true);

      done();
    });
  });
});
