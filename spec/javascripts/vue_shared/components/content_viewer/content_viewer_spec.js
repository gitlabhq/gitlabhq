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
});
