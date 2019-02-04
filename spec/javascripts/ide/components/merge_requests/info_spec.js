import Vue from 'vue';
import '~/behaviors/markdown/render_gfm';
import { createStore } from '~/ide/stores';
import Info from '~/ide/components/merge_requests/info.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';

describe('IDE merge request details', () => {
  let Component;
  let vm;

  beforeAll(() => {
    Component = Vue.extend(Info);
  });

  beforeEach(() => {
    const store = createStore();
    store.state.currentProjectId = 'gitlab-ce';
    store.state.currentMergeRequestId = 1;
    store.state.projects['gitlab-ce'] = {
      mergeRequests: {
        1: {
          iid: 1,
          title: 'Testing',
          title_html: '<span class="title-html">Testing</span>',
          description: 'Description',
          description_html: '<p class="description-html">Description HTML</p>',
        },
      },
    };

    vm = createComponentWithStore(Component, store).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders merge request IID', () => {
    expect(vm.$el.querySelector('.detail-page-header').textContent).toContain('!1');
  });

  it('renders title as HTML', () => {
    expect(vm.$el.querySelector('.title-html')).not.toBe(null);
    expect(vm.$el.querySelector('.title').textContent).toContain('Testing');
  });

  it('renders description as HTML', () => {
    expect(vm.$el.querySelector('.description-html')).not.toBe(null);
    expect(vm.$el.querySelector('.description').textContent).toContain('Description HTML');
  });
});
