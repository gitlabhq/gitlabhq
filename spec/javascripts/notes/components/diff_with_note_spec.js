import Vue from 'vue';
import DiffWithNote from '~/notes/components/diff_with_note.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';
import { diffDiscussionMock, imageDiffDiscussionMock } from '../mock_data';

describe('diff_with_note', () => {
  let vm;
  const Component = Vue.extend(DiffWithNote);
  const props = {
    discussion: diffDiscussionMock,
  };
  const selectors = {
    get container() {
      return vm.$refs.fileHolder;
    },
    get diffTable() {
      return this.container.querySelector('.diff-content table');
    },
    get diffRows() {
      return this.container.querySelectorAll('.diff-content .line-holder');
    },
    get noteRow() {
      return this.container.querySelector('.diff-content .notes-holder');
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
      expect(selectors.diffRows.length).toBe(4);
    });

    it('shows notes row', () => {
      expect(selectors.noteRow).toExist();
    });
  });

  describe('image diff', () => {
    it('shows image diff', () => {
      props.discussion = imageDiffDiscussionMock;

      vm = mountComponent(Component, props);

      expect(selectors.container).toHaveClass('js-image-file');
      expect(selectors.diffTable).not.toExist();
    });
  });
});
