import Vue from 'vue';
import formComponent from '~/issue_show/components/form.vue';

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
          lockedWarningVisible: false,
        },
        markdownPreviewUrl: '/',
        markdownDocs: '/',
        projectsAutocompleteUrl: '/',
      },
    }).$mount();

    Vue.nextTick(done);
  });

  it('hides locked warning by default', () => {
    expect(
      vm.$el.querySelector('.alert'),
    ).toBeNull();
  });

  it('shows locked warning if formState is different', (done) => {
    vm.formState.lockedWarningVisible = true;

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('.alert'),
      ).not.toBeNull();

      done();
    });
  });
});
