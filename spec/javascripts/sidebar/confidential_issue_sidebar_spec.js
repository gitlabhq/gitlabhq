import Vue from 'vue';
import confidentialIssueSidebar from '~/sidebar/components/confidential/confidential_issue_sidebar.vue';

describe('Confidential Issue Sidebar Block', () => {
  let vm1;
  let vm2;

  beforeEach(() => {
    const Component = Vue.extend(confidentialIssueSidebar);
    const service = {
      update: () => new Promise((resolve, reject) => {
        resolve(true);
        reject('failed!');
      }),
    };

    vm1 = new Component({
      propsData: {
        isConfidential: true,
        isEditable: true,
        service,
      },
    }).$mount();

    vm2 = new Component({
      propsData: {
        isConfidential: false,
        isEditable: false,
        service,
      },
    }).$mount();
  });

  it('shows if confidential and/or editable', () => {
    expect(
      vm1.$el.innerHTML.includes('Edit'),
    ).toBe(true);

    expect(
      vm1.$el.innerHTML.includes('This issue is confidential'),
    ).toBe(true);

    expect(
      vm2.$el.innerHTML.includes('Not confidential'),
    ).toBe(true);
  });

  it('displays the edit form when editable', (done) => {
    expect(vm1.edit).toBe(false);

    vm1.$el.querySelector('.confidential-edit').click();

    expect(vm1.edit).toBe(true);

    setTimeout(() => {
      expect(
        vm1.$el
          .innerHTML
          .includes('You are going to turn off the confidentiality.'),
      ).toBe(true);

      done();
    });
  });
});
