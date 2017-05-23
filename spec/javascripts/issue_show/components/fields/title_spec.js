import Vue from 'vue';
import Store from '~/issue_show/stores';
import titleField from '~/issue_show/components/fields/title.vue';
<<<<<<< HEAD
<<<<<<< HEAD
import '~/templates/issuable_template_selectors';
=======
>>>>>>> b1affe0... Issue inline edit title field
=======
>>>>>>> 3301ca1... Fixed up the template dropdown to correctly work

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
<<<<<<< HEAD
        formState: store.formState,
=======
        store,
>>>>>>> b1affe0... Issue inline edit title field
      },
    }).$mount();
  });

  it('renders form control with formState title', () => {
    expect(
      vm.$el.querySelector('.form-control').value,
    ).toBe('test');
  });
<<<<<<< HEAD
<<<<<<< HEAD

  it('does not render template selector if no templates exist', () => {
    expect(
      vm.$el.querySelector('.js-issuable-selector-wrap'),
    ).toBeNull();
  });

  it('renders template selector when templates exists', (done) => {
    spyOn(gl, 'IssuableTemplateSelectors');
    vm.issuableTemplates = ['test'];

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('.js-issuable-selector-wrap'),
      ).not.toBeNull();

      done();
    });
  });
=======
>>>>>>> b1affe0... Issue inline edit title field
=======
>>>>>>> 3301ca1... Fixed up the template dropdown to correctly work
});
