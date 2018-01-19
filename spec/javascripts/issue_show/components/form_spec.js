import Vue from 'vue';
import formComponent from '~/issue_show/components/form.vue';

describe('Inline edit form component', () => {
  let vm;

  beforeEach((done) => {
    const Component = Vue.extend(formComponent);

    vm = new Component({
      propsData: {
        canDestroy: true,
        formState: {
          title: 'b',
          description: 'a',
          lockedWarningVisible: false,
        },
        markdownPreviewPath: '/',
        markdownDocsPath: '/',
        projectPath: '/',
        projectNamespace: '/',
      },
    }).$mount();

    Vue.nextTick(done);
  });

  it('does not render template selector if no templates exist', () => {
    expect(
      vm.$el.querySelector('.js-issuable-selector-wrap'),
    ).toBeNull();
  });

  it('renders template selector when templates exists', (done) => {
    vm.issuableTemplates = ['test'];

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('.js-issuable-selector-wrap'),
      ).not.toBeNull();

      done();
    });
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
