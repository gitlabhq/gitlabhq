import Vue from 'vue';
import formComponent from '~/issue_show/components/form.vue';
<<<<<<< HEAD
import '~/templates/issuable_template_selector';
import '~/templates/issuable_template_selectors';
=======
>>>>>>> 982ab87... Added specs for testing when warning is visible

describe('Inline edit form component', () => {
  let vm;

  beforeEach((done) => {
    const Component = Vue.extend(formComponent);

    vm = new Component({
      propsData: {
        canDestroy: true,
        canMove: true,
        formState: {
          title: 'b',
          description: 'a',
<<<<<<< HEAD
=======
          lockedWarningVisible: false,
>>>>>>> 982ab87... Added specs for testing when warning is visible
        },
        markdownPreviewUrl: '/',
        markdownDocs: '/',
        projectsAutocompleteUrl: '/',
      },
    }).$mount();

    Vue.nextTick(done);
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
=======
=======
  it('hides locked warning by default', () => {
    expect(
      vm.$el.querySelector('.alert'),
    ).toBeNull();
  });

>>>>>>> 95efe5b... Added test to check if warning is not visible
  it('shows locked warning if formState is different', (done) => {
    vm.formState.lockedWarningVisible = true;

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('.alert'),
>>>>>>> 982ab87... Added specs for testing when warning is visible
      ).not.toBeNull();

      done();
    });
  });
});
