import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { GREEN_BOX_IMAGE_URL } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import contentViewer from '~/vue_shared/components/content_viewer/content_viewer.vue';
import '~/behaviors/markdown/render_gfm';

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
      type: 'markdown',
    });

    const previewContainer = vm.$el.querySelector('.md-previewer');

    setTimeout(() => {
      expect(previewContainer.textContent).toContain('testing');

      done();
    });
  });

  it('renders image preview', done => {
    createComponent({
      path: GREEN_BOX_IMAGE_URL,
      fileSize: 1024,
      type: 'image',
    });

    setTimeout(() => {
      expect(vm.$el.querySelector('img').getAttribute('src')).toBe(GREEN_BOX_IMAGE_URL);

      done();
    });
  });

  it('renders fallback download control', done => {
    createComponent({
      path: 'test.abc',
      fileSize: 1024,
    });

    setTimeout(() => {
      expect(vm.$el.querySelector('.file-info').textContent.trim()).toContain('test.abc');
      expect(vm.$el.querySelector('.file-info').textContent.trim()).toContain('(1.00 KiB)');
      expect(vm.$el.querySelector('.btn.btn-default').textContent.trim()).toContain('Download');

      done();
    });
  });

  it('markdown preview receives the file path as a parameter', done => {
    mock = new MockAdapter(axios);
    spyOn(axios, 'post').and.callThrough();
    mock.onPost(`${gon.relative_url_root}/testproject/preview_markdown`).reply(200, {
      body: '<b>testing</b>',
    });

    createComponent({
      path: 'test.md',
      content: '*  Test',
      projectPath: 'testproject',
      type: 'markdown',
      filePath: 'foo/test.md',
    });

    setTimeout(() => {
      expect(axios.post).toHaveBeenCalledWith(
        `${gon.relative_url_root}/testproject/preview_markdown`,
        { path: 'foo/test.md', text: '*  Test' },
        jasmine.any(Object),
      );

      done();
    });
  });
});
