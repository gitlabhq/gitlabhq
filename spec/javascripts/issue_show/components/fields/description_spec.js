import Vue from 'vue';
import descriptionField from '~/issue_show/components/fields/description.vue';

describe('Description field component', () => {
  let vm;

  beforeEach((done) => {
    const Component = Vue.extend(descriptionField);

    // Needs an el in the DOM to be able to test the element is focused
    const el = document.createElement('div');

    document.body.appendChild(el);

    vm = new Component({
      el,
      propsData: {
        formState: {
          description: '',
        },
        markdownDocs: '/',
        markdownPreviewUrl: '/',
      },
    }).$mount();

    Vue.nextTick(done);
  });

  it('focuses field when mounted', () => {
    expect(
      document.activeElement,
    ).toBe(vm.$refs.textarea);
  });
});
