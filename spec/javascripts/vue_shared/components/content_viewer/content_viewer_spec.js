import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import contentViewer from '~/vue_shared/components/content_viewer/content_viewer.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('ContentViewer', () => {
  let vm;
  let mock;

  function createComponent(props) {
    const ContentViewer = Vue.extend(contentViewer);
    vm = mountComponent(ContentViewer, props);
  }

  afterEach(() => {
    vm.$destroy();
    if (mock) mock.restore();
  });

  it('markdown preview renders + loads rendered markdown from server', done => {
    mock = new MockAdapter(axios);
    mock.onPost(`${gon.relative_url_root}/testproject/preview_markdown`).reply(200, {
      body: '<b>testing</b>',
    });

    createComponent({
      path: 'test.md',
      content: '*  Test',
      projectPath: 'testproject',
    });

    const previewContainer = vm.$el.querySelector('.md-previewer');

    setTimeout(() => {
      expect(previewContainer.textContent).toContain('testing');

      done();
    });
  });

  it('renders image preview', done => {
    createComponent({
      path: 'test.jpg',
      fileSize: 1024,
    });

    setTimeout(() => {
      expect(vm.$el.querySelector('.image_file img').getAttribute('src')).toBe('test.jpg');

      done();
    });
  });

  it('renders fallback download control', done => {
    createComponent({
      path: 'test.abc',
      fileSize: 1024,
    });

    setTimeout(() => {
      expect(vm.$el.querySelector('.file-info').textContent.trim()).toContain(
        'test.abc (1.00 KiB)',
      );
      expect(vm.$el.querySelector('.btn.btn-default').textContent.trim()).toContain('Download');

      done();
    });
  });
});
