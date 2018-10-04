import Vue from 'vue';
import diffViewer from '~/vue_shared/components/diff_viewer/diff_viewer.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { GREEN_BOX_IMAGE_URL, RED_BOX_IMAGE_URL } from 'spec/test_constants';

describe('DiffViewer', () => {
  let vm;

  function createComponent(props) {
    const DiffViewer = Vue.extend(diffViewer);
    vm = mountComponent(DiffViewer, props);
  }

  afterEach(() => {
    vm.$destroy();
  });

  it('renders image diff', done => {
    window.gon = {
      relative_url_root: '',
    };

    createComponent({
      diffMode: 'replaced',
      newPath: GREEN_BOX_IMAGE_URL,
      newSha: 'ABC',
      oldPath: RED_BOX_IMAGE_URL,
      oldSha: 'DEF',
      projectPath: '',
    });

    setTimeout(() => {
      expect(vm.$el.querySelector('.deleted .image_file img').getAttribute('src')).toBe(
        `//raw/DEF/${RED_BOX_IMAGE_URL}`,
      );

      expect(vm.$el.querySelector('.added .image_file img').getAttribute('src')).toBe(
        `//raw/ABC/${GREEN_BOX_IMAGE_URL}`,
      );

      done();
    });
  });

  it('renders fallback download diff display', done => {
    createComponent({
      diffMode: 'replaced',
      newPath: 'test.abc',
      newSha: 'ABC',
      oldPath: 'testold.abc',
      oldSha: 'DEF',
    });

    setTimeout(() => {
      expect(vm.$el.querySelector('.deleted .file-info').textContent.trim()).toContain(
        'testold.abc',
      );
      expect(vm.$el.querySelector('.deleted .btn.btn-default').textContent.trim()).toContain(
        'Download',
      );

      expect(vm.$el.querySelector('.added .file-info').textContent.trim()).toContain('test.abc');
      expect(vm.$el.querySelector('.added .btn.btn-default').textContent.trim()).toContain(
        'Download',
      );

      done();
    });
  });
});
