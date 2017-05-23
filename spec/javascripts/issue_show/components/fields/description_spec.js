import Vue from 'vue';
<<<<<<< HEAD
import Store from '~/issue_show/stores';
=======
>>>>>>> 2927802... Focus the description field in the inline form when mounted
import descriptionField from '~/issue_show/components/fields/description.vue';

describe('Description field component', () => {
  let vm;
<<<<<<< HEAD
  let store;

  beforeEach((done) => {
    const Component = Vue.extend(descriptionField);
    store = new Store({
      titleHtml: '',
      descriptionHtml: '',
      issuableRef: '',
    });
    store.formState.description = 'test';

    vm = new Component({
      propsData: {
        markdownPreviewUrl: '/',
        markdownDocs: '/',
        formState: store.formState,
=======

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
>>>>>>> 2927802... Focus the description field in the inline form when mounted
      },
    }).$mount();

    Vue.nextTick(done);
  });

<<<<<<< HEAD
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
=======
  it('focuses field when mounted', () => {
    expect(
      document.activeElement,
    ).toBe(vm.$refs.textarea);
>>>>>>> 2927802... Focus the description field in the inline form when mounted
  });
});
