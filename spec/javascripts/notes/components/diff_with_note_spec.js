import Vue from 'vue';
import DiffWithNote from '~/notes/components/diff_with_note.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';
import { discussionMock } from '../mock_data';

fdescribe('diff_with_note', () => {
  let vm;
  const Component = Vue.extend(DiffWithNote);
  const props = {
    discussion: discussionMock,
  };
  const selectors = {
    get container() {
      return vm.$refs.fileHolder;
    },
    get diffTable() {
      return this.container.querySelector('.diff-content table');
    },
  };

  describe('text diff', () => {
    it('shows text diff', () => {
      props.discussion.diff_file.text = true;
      vm = mountComponent(Component, props);

      expect(selectors.container).toHaveClass('text-file');
      expect(selectors.diffTable).toExist();
    });
  });

  describe('image diff', () => {
    it('shows image diff', () => {
      props.discussion.diff_file.text = false;
      vm = mountComponent(Component, props);

      expect(selectors.container).toHaveClass('js-image-file');
      expect(selectors.diffTable).not.toExist();
    });
  });
});
