import Vue from 'vue';
import Vuex from 'vuex';
import diffsModule from '~/diffs/store/modules';
import notesModule from '~/notes/stores/modules';
import DiffFileHeader from '~/diffs/components/diff_file_header.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

const discussionFixture = 'merge_requests/diff_discussion.json';

describe('diff_file_header', () => {
  let vm;
  let props;
  const Component = Vue.extend(DiffFileHeader);
  const store = new Vuex.Store({
    modules: {
      diffs: diffsModule,
      notes: notesModule,
    },
  });

  beforeEach(() => {
    const diffDiscussionMock = getJSONFixture(discussionFixture)[0];
    const diffFile = convertObjectPropsToCamelCase(diffDiscussionMock.diff_file, { deep: true });
    props = {
      diffFile,
      canCurrentUserFork: false,
    };
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('icon', () => {
      beforeEach(() => {
        props.diffFile.blob.icon = 'file-text-o';
      });

      it('returns the blob icon for files', () => {
        props.diffFile.submodule = false;

        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.icon).toBe(props.diffFile.blob.icon);
      });

      it('returns the archive icon for submodules', () => {
        props.diffFile.submodule = true;

        vm = mountComponentWithStore(Component, { props, store });

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

        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.titleLink).toBe(`#${props.diffFile.fileHash}`);
      });

      it('returns the submoduleTreeUrl for submodules', () => {
        props.diffFile.submodule = true;

        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.titleLink).toBe(props.diffFile.submoduleTreeUrl);
      });

      it('returns the submoduleLink for submodules without submoduleTreeUrl', () => {
        Object.assign(props.diffFile, {
          submodule: true,
          submoduleTreeUrl: null,
        });

        vm = mountComponentWithStore(Component, { props, store });

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

        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.filePath).toBe(props.diffFile.filePath);
      });

      it('appends the truncated blob id for submodules', () => {
        props.diffFile.submodule = true;

        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.filePath).toBe(
          `${props.diffFile.filePath} @ ${props.diffFile.blob.id.substr(0, 8)}`,
        );
      });
    });

    describe('titleTag', () => {
      it('returns a link tag if fileHash is set', () => {
        props.diffFile.fileHash = 'some hash';

        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.titleTag).toBe('a');
      });

      it('returns a span tag if fileHash is not set', () => {
        props.diffFile.fileHash = null;

        vm = mountComponentWithStore(Component, { props, store });

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
        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.isUsingLfs).toBe(true);
      });

      it('returns false if file is not stored externally', () => {
        props.diffFile.storedExternally = false;

        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.isUsingLfs).toBe(false);
      });

      it('returns false if file is not stored in LFS', () => {
        props.diffFile.externalStorage = 'not lfs';

        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.isUsingLfs).toBe(false);
      });
    });

    describe('collapseIcon', () => {
      it('returns chevron-down if the diff is expanded', () => {
        props.expanded = true;

        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.collapseIcon).toBe('chevron-down');
      });

      it('returns chevron-right if the diff is collapsed', () => {
        props.expanded = false;

        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.collapseIcon).toBe('chevron-right');
      });
    });

    describe('viewFileButtonText', () => {
      it('contains the truncated content SHA', () => {
        const dummySha = 'deebd00f is no SHA';
        props.diffFile.contentSha = dummySha;

        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.viewFileButtonText).not.toContain(dummySha);
        expect(vm.viewFileButtonText).toContain(dummySha.substr(0, 8));
      });
    });

    describe('viewReplacedFileButtonText', () => {
      it('contains the truncated base SHA', () => {
        const dummySha = 'deadabba sings no more';
        props.diffFile.diffRefs.baseSha = dummySha;

        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.viewReplacedFileButtonText).not.toContain(dummySha);
        expect(vm.viewReplacedFileButtonText).toContain(dummySha.substr(0, 8));
      });
    });
  });

  describe('methods', () => {
    describe('handleToggleFile', () => {
      beforeEach(() => {
        spyOn(vm, '$emit').and.stub();
      });

      it('emits toggleFile if checkTarget is false', () => {
        vm.handleToggleFile(null, false);

        expect(vm.$emit).toHaveBeenCalledWith('toggleFile');
      });

      it('emits toggleFile if checkTarget is true and event target is header', () => {
        vm.handleToggleFile({ target: vm.$refs.header }, true);

        expect(vm.$emit).toHaveBeenCalledWith('toggleFile');
      });

      it('does not emit toggleFile if checkTarget is true and event target is not header', () => {
        vm.handleToggleFile({ target: 'not header' }, true);

        expect(vm.$emit).not.toHaveBeenCalled();
      });
    });
  });

  describe('template', () => {
    describe('collapse toggle', () => {
      const collapseToggle = () => vm.$el.querySelector('.diff-toggle-caret');

      it('is visible if collapsible is true', () => {
        props.collapsible = true;

        vm = mountComponentWithStore(Component, { props, store });

        expect(collapseToggle()).not.toBe(null);
      });

      it('is hidden if collapsible is false', () => {
        props.collapsible = false;

        vm = mountComponentWithStore(Component, { props, store });

        expect(collapseToggle()).toBe(null);
      });
    });

    it('displays an file icon in the title', () => {
      vm = mountComponentWithStore(Component, { props, store });
      expect(vm.$el.querySelector('svg.js-file-icon use').getAttribute('xlink:href')).toContain(
        'ruby',
      );
    });

    describe('file paths', () => {
      const filePaths = () => vm.$el.querySelectorAll('.file-title-name');

      it('displays the path of a added file', () => {
        props.diffFile.renamedFile = false;

        vm = mountComponentWithStore(Component, { props, store });

        expect(filePaths()).toHaveLength(1);
        expect(filePaths()[0]).toHaveText(props.diffFile.filePath);
      });

      it('displays path for deleted file', () => {
        props.diffFile.renamedFile = false;
        props.diffFile.deletedFile = true;

        vm = mountComponentWithStore(Component, { props, store });

        expect(filePaths()).toHaveLength(1);
        expect(filePaths()[0]).toHaveText(`${props.diffFile.filePath} deleted`);
      });

      it('displays old and new path if the file was renamed', () => {
        props.diffFile.renamedFile = true;

        vm = mountComponentWithStore(Component, { props, store });

        expect(filePaths()).toHaveLength(2);
        expect(filePaths()[0]).toHaveText(props.diffFile.oldPath);
        expect(filePaths()[1]).toHaveText(props.diffFile.newPath);
      });
    });

    it('displays a copy to clipboard button', () => {
      vm = mountComponentWithStore(Component, { props, store });

      const button = vm.$el.querySelector('.btn-clipboard');
      expect(button).not.toBe(null);
      expect(button.dataset.clipboardText).toBe('{"text":"files/ruby/popen.rb","gfm":"`files/ruby/popen.rb`"}');
    });

    describe('file mode', () => {
      it('it displays old and new file mode if it changed', () => {
        props.diffFile.modeChanged = true;

        vm = mountComponentWithStore(Component, { props, store });

        const { fileMode } = vm.$refs;
        expect(fileMode).not.toBe(undefined);
        expect(fileMode).toContainText(props.diffFile.aMode);
        expect(fileMode).toContainText(props.diffFile.bMode);
      });

      it('does not display the file mode if it has not changed', () => {
        props.diffFile.modeChanged = false;

        vm = mountComponentWithStore(Component, { props, store });

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

        vm = mountComponentWithStore(Component, { props, store });

        expect(lfsLabel()).not.toBe(null);
        expect(lfsLabel()).toHaveText('LFS');
      });

      it('does not display the LFS label for files stored in repository', () => {
        props.diffFile.storedExternally = false;

        vm = mountComponentWithStore(Component, { props, store });

        expect(lfsLabel()).toBe(null);
      });
    });

    describe('edit button', () => {
      it('should not render edit button if addMergeRequestButtons is not true', () => {
        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.$el.querySelector('.js-edit-blob')).toEqual(null);
      });

      it('should show edit button when file is editable', () => {
        props.addMergeRequestButtons = true;
        props.diffFile.editPath = '/';
        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.$el.querySelector('.js-edit-blob')).toContainText('Edit');
      });

      it('should not show edit button when file is deleted', () => {
        props.addMergeRequestButtons = true;
        props.diffFile.deletedFile = true;
        props.diffFile.editPath = '/';
        vm = mountComponentWithStore(Component, { props, store });

        expect(vm.$el.querySelector('.js-edit-blob')).toEqual(null);
      });
    });

    describe('addMergeRequestButtons', () => {
      beforeEach(() => {
        props.addMergeRequestButtons = true;
        props.diffFile.editPath = '';
      });

      describe('view on environment button', () => {
        const url = 'some.external.url/';
        const title = 'url.title';

        it('displays link to external url', () => {
          props.diffFile.externalUrl = url;
          props.diffFile.formattedExternalUrl = title;

          vm = mountComponentWithStore(Component, { props, store });

          expect(vm.$el.querySelector(`a[href="${url}"]`)).not.toBe(null);
          expect(vm.$el.querySelector(`a[data-original-title="View on ${title}"]`)).not.toBe(null);
        });

        it('hides link if no external url', () => {
          props.diffFile.externalUrl = '';
          props.diffFile.formattedExternalUrl = title;

          vm = mountComponentWithStore(Component, { props, store });

          expect(vm.$el.querySelector(`a[data-original-title="View on ${title}"]`)).toBe(null);
        });
      });
    });

    describe('handles toggle discussions', () => {
      it('dispatches toggleFileDiscussions when user clicks on toggle discussions button', () => {
        const propsCopy = Object.assign({}, props);
        propsCopy.diffFile.submodule = false;
        propsCopy.diffFile.blob = {
          id: '848ed9407c6730ff16edb3dd24485a0eea24292a',
          path: 'lib/base.js',
          name: 'base.js',
          mode: '100644',
          readableText: true,
          icon: 'file-text-o',
        };
        propsCopy.addMergeRequestButtons = true;
        propsCopy.diffFile.deletedFile = true;

        vm = mountComponentWithStore(Component, {
          props: propsCopy,
          store,
        });

        spyOn(vm, 'toggleFileDiscussions');

        vm.$el.querySelector('.js-btn-vue-toggle-comments').click();

        expect(vm.toggleFileDiscussions).toHaveBeenCalled();
      });
    });
  });
});
