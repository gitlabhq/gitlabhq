import Vue from 'vue';
import DiffFileHeader from '~/diffs/components/diff_file_header.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const discussionFixture = 'merge_requests/diff_discussion.json';

describe('diff_file_header', () => {
  let vm;
  let props = {};
  const Component = Vue.extend(DiffFileHeader);

  const selectors = {
    get copyButton() {
      return vm.$el.querySelector('button[data-original-title="Copy file path to clipboard"]');
    },
    get fileName() {
      return vm.$el.querySelector('.file-title-name');
    },
    get titleWrapper() {
      return vm.$refs.titleWrapper;
    },
  };

  beforeEach(() => {
    const diffDiscussionMock = getJSONFixture(discussionFixture)[0];
    const diffFile = convertObjectPropsToCamelCase(diffDiscussionMock.diff_file, { deep: true });
    props = {
      diffFile,
    };
  });

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
      expect(selectors.copyButton.getAttribute('data-clipboard-text')).toBe(
        props.diffFile.submoduleLink,
      );
    });
  });

  describe('changed file', () => {
    beforeEach(() => {
      props.diffFile.submodule = false;
      props.diffFile.discussionPath = 'some/discussion/id';

      vm = mountComponent(Component, props);
    });

    it('shows file type icon', () => {
      expect(vm.$el.innerHTML).toContain('fa-file-text-o');
    });

    it('links to discussion path', () => {
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
      expect(selectors.copyButton.getAttribute('data-clipboard-text')).toBe(
        props.diffFile.filePath,
      );
    });

    it('shows file mode change', done => {
      vm.diffFile = {
        ...props.diffFile,
        modeChanged: true,
        aMode: '100755',
        bMode: '100644',
      };

      Vue.nextTick(() => {
        expect(vm.$refs.fileMode.textContent.trim()).toBe('100755 → 100644');
        done();
      });
    });

    it('has link to View file', () => {
      const buttonText = `View file @ ${vm.truncatedContentSha}`;

      expect(vm.$el.querySelector('.js-view-file').innerText.trim()).toEqual(buttonText);
    });
  });

  describe('replaced file', () => {
    beforeEach(() => {
      props.diffFile = {
        ...props.diffFile,
        baseSha: 'abcdef1234567890',
        replacedViewPath: '/base/sha/path.jpg',
        viewPath: '/base/sha/path.jpg',
      };

      props.addMergeRequestButtons = true;

      vm = mountComponent(Component, props);
    });

    it('has link to View replaced file', () => {
      const buttonText = `View replaced file @ ${vm.truncatedBaseSha}`;

      expect(vm.$el.querySelector('.js-view-file').innerText.trim()).toEqual(buttonText);
    });
  });
});
