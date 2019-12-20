import Vue from 'vue';
import { mountComponentWithStore } from 'spec/helpers';
import DiffWithNote from '~/notes/components/diff_with_note.vue';
import { createStore } from '~/mr_notes/stores';

const discussionFixture = 'merge_requests/diff_discussion.json';
const imageDiscussionFixture = 'merge_requests/image_diff_discussion.json';

describe('diff_with_note', () => {
  let store;
  let vm;
  const diffDiscussionMock = getJSONFixture(discussionFixture)[0];
  const diffDiscussion = diffDiscussionMock;
  const Component = Vue.extend(DiffWithNote);
  const props = {
    discussion: diffDiscussion,
  };
  const selectors = {
    get container() {
      return vm.$el;
    },
    get diffTable() {
      return this.container.querySelector('.diff-content table');
    },
    get diffRows() {
      return this.container.querySelectorAll('.diff-content .line_holder');
    },
    get noteRow() {
      return this.container.querySelector('.diff-content .notes_holder');
    },
  };

  beforeEach(() => {
    store = createStore();
    store.replaceState({
      ...store.state,
      notes: {
        noteableData: {
          current_user: {},
        },
      },
    });
  });

  describe('text diff', () => {
    beforeEach(() => {
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('removes trailing "+" char', () => {
      const richText = vm.$el.querySelectorAll('.line_holder')[4].querySelector('.line_content')
        .textContent[0];

      expect(richText).not.toEqual('+');
    });

    it('removes trailing "-" char', () => {
      const richText = vm.$el.querySelector('#LC13').parentNode.textContent[0];

      expect(richText).not.toEqual('-');
    });

    it('shows text diff', () => {
      expect(selectors.container).toHaveClass('text-file');
      expect(selectors.diffTable).toExist();
    });

    it('shows diff lines', () => {
      expect(selectors.diffRows.length).toBe(12);
    });

    it('shows notes row', () => {
      expect(selectors.noteRow).toExist();
    });
  });

  describe('image diff', () => {
    beforeEach(() => {
      const imageDiffDiscussionMock = getJSONFixture(imageDiscussionFixture)[0];
      props.discussion = imageDiffDiscussionMock;
    });

    it('shows image diff', () => {
      vm = mountComponentWithStore(Component, { props, store });

      expect(selectors.diffTable).not.toExist();
    });
  });
});
