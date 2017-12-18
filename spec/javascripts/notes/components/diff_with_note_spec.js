import Vue from 'vue';
import DiffWithNote from '~/notes/components/diff_with_note.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';
import { diffDiscussionMock } from '../mock_data';

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
      return this.container.querySelectorAll('.diff-content table tr');
    },
  };

  describe('text diff', () => {
    it('shows text diff', () => {
      props.discussion.notes[0].diff_file.text = true;
      props.discussion.notes[0].diff_file.filePath = 'some/path';

      vm = mountComponent(Component, props);

      expect(selectors.container).toHaveClass('text-file');
      expect(selectors.diffTable).toExist();
      expect(selectors.diffRows.length).toBe(6);
    });
  });

  describe('image diff', () => {
    it('shows image diff', () => {
      props.discussion.notes[0].diff_file.text = false;
      vm = mountComponent(Component, props);

      expect(selectors.container).toHaveClass('js-image-file');
      expect(selectors.diffTable).not.toExist();
    });
  });
});
