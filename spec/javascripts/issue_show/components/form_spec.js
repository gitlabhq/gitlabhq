import Vue from 'vue';
import formComponent from '~/issue_show/components/form.vue';
import '~/templates/issuable_template_selector';
import '~/templates/issuable_template_selectors';

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
        },
        markdownPreviewUrl: '/',
        markdownDocs: '/',
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
    spyOn(gl, 'IssuableTemplateSelectors');
    vm.issuableTemplates = ['test'];

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('.js-issuable-selector-wrap'),
      ).not.toBeNull();

      done();
    });
  });
});
