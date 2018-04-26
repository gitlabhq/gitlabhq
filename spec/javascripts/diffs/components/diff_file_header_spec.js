import Vue from 'vue';
import DiffFileHeader from '~/diffs/components/diff_file_header.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const discussionFixture = 'merge_requests/diff_discussion.json';

describe('diff_file_header', () => {
  let vm;
  let props;
  const Component = Vue.extend(DiffFileHeader);

  beforeEach(() => {
    const diffDiscussionMock = getJSONFixture(discussionFixture)[0];
    const diffFile = convertObjectPropsToCamelCase(diffDiscussionMock.diff_file, { deep: true });
    props = {
      diffFile,
    };
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('icon', () => {
      beforeEach(() => {
        props.diffFile.blob.icon = 'dummy icon';
      });

      it('returns the blob icon for files', () => {
        props.diffFile.submodule = false;

        vm = mountComponent(Component, props);

        expect(vm.icon).toBe(props.diffFile.blob.icon);
      });

      it('returns the archive icon for submodules', () => {
        props.diffFile.submodule = true;

        vm = mountComponent(Component, props);

        expect(vm.icon).toBe('archive');
      });
    });

    describe('titleLink', () => {
      beforeEach(() => {
        Object.assign(props.diffFile, {
          fileHash: 'badc0ffee',
          submoduleLink: 'link://to/submodule',
          submoduleTreeUrl: 'some://tree/url',
        });
      });

      it('returns the fileHash for files', () => {
        props.diffFile.submodule = false;

        vm = mountComponent(Component, props);

        expect(vm.titleLink).toBe(`#${props.diffFile.fileHash}`);
      });

      it('returns the submoduleTreeUrl for submodules', () => {
        props.diffFile.submodule = true;

        vm = mountComponent(Component, props);

        expect(vm.titleLink).toBe(props.diffFile.submoduleTreeUrl);
      });

      it('returns the submoduleLink for submodules without submoduleTreeUrl', () => {
        Object.assign(props.diffFile, {
          submodule: true,
          submoduleTreeUrl: null,
        });

        vm = mountComponent(Component, props);

        expect(vm.titleLink).toBe(props.diffFile.submoduleLink);
      });
    });

    describe('filePath', () => {
      beforeEach(() => {
        Object.assign(props.diffFile, {
          blob: { id: 'b10b1db10b1d' },
          filePath: 'path/to/file',
        });
      });

      it('returns the filePath for files', () => {
        props.diffFile.submodule = false;

        vm = mountComponent(Component, props);

        expect(vm.filePath).toBe(props.diffFile.filePath);
      });

      it('appends the truncated blob id for submodules', () => {
        props.diffFile.submodule = true;

        vm = mountComponent(Component, props);

        expect(vm.filePath).toBe(
          `${props.diffFile.filePath} @ ${props.diffFile.blob.id.substr(0, 8)}`,
        );
      });
    });

    describe('titleTag', () => {
      it('returns a link tag if fileHash is set', () => {
        props.diffFile.fileHash = 'some hash';

        vm = mountComponent(Component, props);

        expect(vm.titleTag).toBe('a');
      });

      it('returns a span tag if fileHash is not set', () => {
        props.diffFile.fileHash = null;

        vm = mountComponent(Component, props);

        expect(vm.titleTag).toBe('span');
      });
    });

    describe('isUsingLfs', () => {
      beforeEach(() => {
        Object.assign(props.diffFile, {
          storedExternally: true,
          externalStorage: 'lfs',
        });
      });

      it('returns true if file is stored in LFS', () => {
        vm = mountComponent(Component, props);

        expect(vm.isUsingLfs).toBe(true);
      });

      it('returns false if file is not stored externally', () => {
        props.diffFile.storedExternally = false;

        vm = mountComponent(Component, props);

        expect(vm.isUsingLfs).toBe(false);
      });

      it('returns false if file is not stored in LFS', () => {
        props.diffFile.externalStorage = 'not lfs';

        vm = mountComponent(Component, props);

        expect(vm.isUsingLfs).toBe(false);
      });
    });

    describe('collapseIcon', () => {
      it('returns chevron-down if the diff is expanded', () => {
        props.expanded = true;

        vm = mountComponent(Component, props);

        expect(vm.collapseIcon).toBe('chevron-down');
      });

      it('returns chevron-right if the diff is collapsed', () => {
        props.expanded = false;

        vm = mountComponent(Component, props);

        expect(vm.collapseIcon).toBe('chevron-right');
      });
    });

    describe('isDiscussionsExpanded', () => {
      beforeEach(() => {
        Object.assign(props, {
          discussionsExpanded: true,
          expanded: true,
        });
      });

      it('returns true if diff and discussion are expanded', () => {
        vm = mountComponent(Component, props);

        expect(vm.isDiscussionsExpanded).toBe(true);
      });

      it('returns false if discussion is collapsed', () => {
        props.discussionsExpanded = false;

        vm = mountComponent(Component, props);

        expect(vm.isDiscussionsExpanded).toBe(false);
      });

      it('returns false if diff is collapsed', () => {
        props.expanded = false;

        vm = mountComponent(Component, props);

        expect(vm.isDiscussionsExpanded).toBe(false);
      });
    });

    describe('viewFileButtonText', () => {
      it('contains the truncated content SHA', () => {
        const dummySha = 'deebd00f is no SHA';
        props.diffFile.contentSha = dummySha;

        vm = mountComponent(Component, props);

        expect(vm.viewFileButtonText).not.toContain(dummySha);
        expect(vm.viewFileButtonText).toContain(dummySha.substr(0, 8));
      });
    });

    describe('viewReplacedFileButtonText', () => {
      it('contains the truncated base SHA', () => {
        const dummySha = 'deadabba sings no more';
        props.diffFile.diffRefs.baseSha = dummySha;

        vm = mountComponent(Component, props);

        expect(vm.viewReplacedFileButtonText).not.toContain(dummySha);
        expect(vm.viewReplacedFileButtonText).toContain(dummySha.substr(0, 8));
      });
    });
  });

  describe('methods', () => {
    describe('handleToggle', () => {
      beforeEach(() => {
        spyOn(vm, '$emit').and.stub();
      });

      it('emits toggleFile if checkTarget is false', () => {
        vm.handleToggle(null, false);

        expect(vm.$emit).toHaveBeenCalledWith('toggleFile');
      });

      it('emits toggleFile if checkTarget is true and event target is header', () => {
        vm.handleToggle({ target: vm.$refs.header }, true);

        expect(vm.$emit).toHaveBeenCalledWith('toggleFile');
      });

      it('does not emit toggleFile if checkTarget is true and event target is not header', () => {
        vm.handleToggle({ target: 'not header' }, true);

        expect(vm.$emit).not.toHaveBeenCalled();
      });
    });
  });

  describe('template', () => {
    describe('collapse toggle', () => {
      const collapseToggle = () => vm.$el.querySelector('.diff-toggle-caret');

      it('is visible if collapsible is true', () => {
        props.collapsible = true;

        vm = mountComponent(Component, props);

        expect(collapseToggle()).not.toBe(null);
      });

      it('is hidden if collapsible is false', () => {
        props.collapsible = false;

        vm = mountComponent(Component, props);

        expect(collapseToggle()).toBe(null);
      });
    });

    it('displays an icon in the title', () => {
      vm = mountComponent(Component, props);

      const icon = vm.$el.querySelector(`i[class="fa fa-fw fa-${vm.icon}"]`);
      expect(icon).not.toBe(null);
    });

    describe('file paths', () => {
      const filePaths = () => vm.$el.querySelectorAll('.file-title-name');

      it('displays the path of a deleted/added file', () => {
        props.diffFile.renamedFile = false;

        vm = mountComponent(Component, props);

        expect(filePaths()).toHaveLength(1);
        expect(filePaths()[0]).toHaveText(props.diffFile.filePath);
      });

      it('displays old and new path if the file was renamed', () => {
        props.diffFile.renamedFile = true;

        vm = mountComponent(Component, props);

        expect(filePaths()).toHaveLength(2);
        expect(filePaths()[0]).toHaveText(props.diffFile.oldPath);
        expect(filePaths()[1]).toHaveText(props.diffFile.newPath);
      });
    });

    it('displays a copy to clipboard button', () => {
      vm = mountComponent(Component, props);

      const button = vm.$el.querySelector('.btn-clipboard');
      expect(button).not.toBe(null);
      expect(button.dataset.clipboardText).toBe(props.diffFile.filePath);
    });

    describe('file mode', () => {
      it('it displays old and new file mode if it changed', () => {
        props.diffFile.modeChanged = true;

        vm = mountComponent(Component, props);

        const { fileMode } = vm.$refs;
        expect(fileMode).not.toBe(undefined);
        expect(fileMode).toContainText(props.diffFile.aMode);
        expect(fileMode).toContainText(props.diffFile.bMode);
      });

      it('does not display the file mode if it has not changed', () => {
        props.diffFile.modeChanged = false;

        vm = mountComponent(Component, props);

        const { fileMode } = vm.$refs;
        expect(fileMode).toBe(undefined);
      });
    });

    describe('LFS label', () => {
      const lfsLabel = () => vm.$el.querySelector('.label-lfs');

      it('displays the LFS label for files stored in LFS', () => {
        Object.assign(props.diffFile, {
          storedExternally: true,
          externalStorage: 'lfs',
        });

        vm = mountComponent(Component, props);

        expect(lfsLabel()).not.toBe(null);
        expect(lfsLabel()).toHaveText('LFS');
      });

      it('does not display the LFS label for files stored in repository', () => {
        props.diffFile.storedExternally = false;

        vm = mountComponent(Component, props);

        expect(lfsLabel()).toBe(null);
      });
    });
  });
});
