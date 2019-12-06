import Vue from 'vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { GREEN_BOX_IMAGE_URL, RED_BOX_IMAGE_URL } from 'spec/test_constants';
import diffViewer from '~/vue_shared/components/diff_viewer/diff_viewer.vue';

describe('DiffViewer', () => {
  const requiredProps = {
    diffMode: 'replaced',
    diffViewerMode: 'image',
    newPath: GREEN_BOX_IMAGE_URL,
    newSha: 'ABC',
    oldPath: RED_BOX_IMAGE_URL,
    oldSha: 'DEF',
  };
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

    createComponent(
      Object.assign({}, requiredProps, {
        projectPath: '',
      }),
    );

    setTimeout(() => {
      expect(vm.$el.querySelector('.deleted img').getAttribute('src')).toBe(
        `//raw/DEF/${RED_BOX_IMAGE_URL}`,
      );

      expect(vm.$el.querySelector('.added img').getAttribute('src')).toBe(
        `//raw/ABC/${GREEN_BOX_IMAGE_URL}`,
      );

      done();
    });
  });

  it('renders fallback download diff display', done => {
    createComponent(
      Object.assign({}, requiredProps, {
        diffViewerMode: 'added',
        newPath: 'test.abc',
        oldPath: 'testold.abc',
      }),
    );

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

  it('renders renamed component', () => {
    createComponent(
      Object.assign({}, requiredProps, {
        diffMode: 'renamed',
        diffViewerMode: 'renamed',
        newPath: 'test.abc',
        oldPath: 'testold.abc',
      }),
    );

    expect(vm.$el.textContent).toContain('File moved');
  });

  it('renders mode changed component', () => {
    createComponent(
      Object.assign({}, requiredProps, {
        diffMode: 'mode_changed',
        newPath: 'test.abc',
        oldPath: 'testold.abc',
        aMode: '123',
        bMode: '321',
      }),
    );

    expect(vm.$el.textContent).toContain('File mode changed from 123 to 321');
  });
});
