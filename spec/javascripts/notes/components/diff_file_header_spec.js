import Vue from 'vue';
import DiffFileHeader from '~/notes/components/diff_file_header.vue';
import { diffDiscussionMock } from '../mock_data';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('diff_file_header', () => {
  let vm;
  const props = {
    diffFile: diffDiscussionMock.diff_file,
  };
  const Component = Vue.extend(DiffFileHeader);
  const selectors = {
    get copyButton() {
      return vm.$el.querySelector('button[data-title="Copy file path to clipboard"]');
    },
    get fileName() {
      return vm.$el.querySelector('.file-title-name');
    },
    get titleWrapper() {
      return vm.$refs.titleWrapper;
    },
  };

  describe('submodule', () => {
    beforeEach(() => {
      props.diffFile.submodule = true;
      props.diffFile.submoduleLink = '<a href="/bha">Submodule</a>';

      vm = mountComponent(Component, props);
    });

    it('shows submoduleLink', () => {
      expect(selectors.fileName.innerHTML).toBe(props.diffFile.submoduleLink);
    });

    it('has button to copy blob path', () => {
      expect(selectors.copyButton).toExist();
      expect(selectors.copyButton.getAttribute('data-clipboard-text')).toBe(props.diffFile.submoduleLink);
    });
  });

  describe('changed file', () => {
    beforeEach(() => {
      props.diffFile.submodule = false;
      props.diffFile.discussionPath = 'some/discussion/id';
    });

    it('shows file type icon', () => {
      vm = mountComponent(Component, props);

      expect(vm.$el.innerHTML).toContain('fa-file-image-o');
    });

    it('links to discussion path', () => {
      vm = mountComponent(Component, props);

      expect(selectors.titleWrapper).toExist();
      expect(selectors.titleWrapper.tagName).toBe('A');
      expect(selectors.titleWrapper.getAttribute('href')).toBe(props.diffFile.discussionPath);
    });

    it('shows plain title if no link given', () => {
      props.diffFile.discussionPath = undefined;

      vm = mountComponent(Component, props);

      expect(selectors.titleWrapper.tagName).not.toBe('A');
      expect(selectors.titleWrapper.href).toBeFalsy();
    });

    it('has button to copy file path', () => {
      expect(selectors.copyButton).toExist();
      expect(selectors.copyButton.getAttribute('data-clipboard-text')).toBe(props.diffFile.filePath);
    });

    it('shows file mode change', () => {
      props.diffFile = {
        ...props.diffFile,
        modeChanged: true,
        aMode: '100755',
        bMode: '100644',
      };
      vm = mountComponent(Component, props);

      expect(
        vm.$refs.fileMode.textContent.trim(),
      ).toBe('100755 → 100644');
    });
  });
});
