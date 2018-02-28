import Vue from 'vue';
import placeholderSystemNote from '~/notes/components/issue_placeholder_system_note.vue';

describe('issue placeholder system note component', () => {
  let mountComponent;
  beforeEach(() => {
    const PlaceholderSystemNote = Vue.extend(placeholderSystemNote);

    mountComponent = props => new PlaceholderSystemNote({
      propsData: {
        note: {
          body: props,
        },
      },
    }).$mount();
  });

  it('should render system note placeholder with plain text', () => {
    const vm = mountComponent('This is a placeholder');

    expect(vm.$el.tagName).toEqual('LI');
    expect(vm.$el.querySelector('.timeline-content em').textContent.trim()).toEqual('This is a placeholder');
  });
});
