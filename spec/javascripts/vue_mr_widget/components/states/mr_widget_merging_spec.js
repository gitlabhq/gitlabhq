import Vue from 'vue';
import mergingComponent from '~/vue_merge_request_widget/components/states/mr_widget_merging.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('MRWidgetMerging', () => {
  let vm;
  beforeEach(() => {
    const Component = Vue.extend(mergingComponent);

    vm = mountComponent(Component, { mr: {
      targetBranchPath: '/branch-path',
      targetBranch: 'branch',
    } });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders information about merge request being merged', () => {
    expect(
      vm.$el.querySelector('.media-body').textContent.trim().replace(/\s\s+/g, ' ').replace(/[\r\n]+/g, ' '),
    ).toContain('This merge request is in the process of being merged');
  });

  it('renders branch information', () => {
    expect(
      vm.$el.querySelector('.mr-info-list').textContent.trim().replace(/\s\s+/g, ' ').replace(/[\r\n]+/g, ' '),
    ).toEqual('The changes will be merged into branch');
    expect(
      vm.$el.querySelector('a').getAttribute('href'),
    ).toEqual('/branch-path');
  });
});
