import Vue from 'vue';
import Store from '~/issue_show/stores';
import descriptionField from '~/issue_show/components/fields/description.vue';

describe('Description field component', () => {
  let vm;
  let store;

  beforeEach((done) => {
    const Component = Vue.extend(descriptionField);
    const el = document.createElement('div');
    store = new Store({
      titleHtml: '',
      descriptionHtml: '',
      issuableRef: '',
    });
    store.formState.description = 'test';

    document.body.appendChild(el);

    vm = new Component({
      el,
      propsData: {
        markdownPreviewUrl: '/',
        markdownDocs: '/',
        formState: store.formState,
      },
    }).$mount();

    Vue.nextTick(done);
  });

  it('renders markdown field with description', () => {
    expect(
      vm.$el.querySelector('.md-area textarea').value,
    ).toBe('test');
  });

  it('renders markdown field with a markdown description', (done) => {
    store.formState.description = '**test**';

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('.md-area textarea').value,
      ).toBe('**test**');

      done();
    });
  });

  it('focuses field when mounted', () => {
    expect(
      document.activeElement,
    ).toBe(vm.$refs.textarea);
  });
});
