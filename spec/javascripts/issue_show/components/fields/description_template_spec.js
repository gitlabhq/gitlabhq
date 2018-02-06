import Vue from 'vue';
import descriptionTemplate from '~/issue_show/components/fields/description_template.vue';

describe('Issue description template component', () => {
  let vm;
  let formState;

  beforeEach((done) => {
    const Component = Vue.extend(descriptionTemplate);
    formState = {
      description: 'test',
    };

    vm = new Component({
      propsData: {
        formState,
        issuableTemplates: [{ name: 'test' }],
        projectPath: '/',
        projectNamespace: '/',
      },
    }).$mount();

    Vue.nextTick(done);
  });

  it('renders templates as JSON array in data attribute', () => {
    expect(
      vm.$el.querySelector('.js-issuable-selector').getAttribute('data-data'),
    ).toBe('[{"name":"test"}]');
  });

  it('updates formState when changing template', () => {
    vm.issuableTemplate.editor.setValue('test new template');

    expect(
      formState.description,
    ).toBe('test new template');
  });

  it('returns formState description with editor getValue', () => {
    formState.description = 'testing new template';

    expect(
      vm.issuableTemplate.editor.getValue(),
    ).toBe('testing new template');
  });
});
