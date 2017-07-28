import Vue from 'vue';
import placeholderNote from '~/notes/components/issue_placeholder_note.vue';

describe('issue placeholder system note component', () => {
  let mountComponent;
  beforeEach(() => {
    const PlaceholderNote = Vue.extend(placeholderNote);

    mountComponent = props => new PlaceholderNote({
      propsData: {
        note: props,
      },
    }).$mount();
  });

  describe('user information', () => {
    it('should render user avatar with link', () => {

    });
  });

  describe('note content', () => {
    it('should render note header information', () => {

    });

    it('should render note body', () => {

    });

    it('should render system note placeholder with markdown', () => {

    });

    it('should render emojis', () => {

    });

    it('should render slash commands', () => {

    });
  });
});
