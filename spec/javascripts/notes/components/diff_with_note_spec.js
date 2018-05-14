import Vue from 'vue';
import DiffWithNote from '~/notes/components/diff_with_note.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const discussionFixture = 'merge_requests/diff_discussion.json';
const imageDiscussionFixture = 'merge_requests/image_diff_discussion.json';

describe('diff_with_note', () => {
  let vm;
  const diffDiscussionMock = getJSONFixture(discussionFixture)[0];
  const diffDiscussion = convertObjectPropsToCamelCase(diffDiscussionMock);
  const Component = Vue.extend(DiffWithNote);
  const props = {
    discussion: diffDiscussion,
  };
  const selectors = {
    get container() {
      return vm.$refs.fileHolder;
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

  describe('text diff', () => {
    beforeEach(() => {
      vm = mountComponent(Component, props);
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
      props.discussion = convertObjectPropsToCamelCase(imageDiffDiscussionMock);
    });

    it('shows image diff', () => {
      vm = mountComponent(Component, props);

      expect(selectors.container).toHaveClass('js-image-file');
      expect(selectors.diffTable).not.toExist();
    });
  });
});
