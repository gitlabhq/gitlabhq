import Vue from 'vue';
import Store from '~/issue_show/stores';
import titleField from '~/issue_show/components/fields/title.vue';

describe('Title field component', () => {
  let vm;
  let store;

  beforeEach(() => {
    const Component = Vue.extend(titleField);
    store = new Store({
      titleHtml: '',
      descriptionHtml: '',
      issuableRef: '',
    });
    store.formState.title = 'test';

    vm = new Component({
      propsData: {
        store,
      },
    }).$mount();
  });

  it('renders form control with formState title', () => {
    expect(
      vm.$el.querySelector('.form-control').value,
    ).toBe('test');
  });
});
