import Vue from 'vue';
import DiffFileHeader from '~/notes/components/diff_file_header.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

fdescribe('diff_file_header', () => {
  let vm;
  let props = {
    diffFile: {
      submodule: false,
      submoduleLink: '<a href="/bha">Submodule</a>', // submodule_link(blob, diff_file.content_sha, diff_file.repository)
      url: '',
      renamedFile: false,
      deletedFile: false,
      modeChanged: false,
      bMode: false, // TODO: check type
      filePath: '/some/file/path',
      oldPath: '',
      newPath: '',
      fileTypeIcon: 'fa-file-image-o', // file_type_icon_class('file', diff_file.b_mode, diff_file.file_path)
    },
  };
  const Component = Vue.extend(DiffFileHeader);

  describe('submodule', () => {
    beforeEach(() => {
      props.diffFile.submodule = false;
      props.diffFile.submoduleLink = '<a href="/bha">Submodule</a>';
    });

    xit('shows archive icon', () => {

    });

    xit('shows submoduleLink', () => {

    });

    xit('has button to copu blob path', () => {
      // check button text and title
    });
  });

  describe('changed file', () => {
    beforeEach(() => {
      props.diffFile.submodule = false;
    });

    it('shows file type icon', () => {
      vm = mountComponent(Component, props);

      expect(vm.$el.innerHTML).toContain('fa-file-image-o');
    });

    it('has button to copy file path', () => {
      // const filePath
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
