import Vue from 'vue';
import closedComponent from '~/vue_merge_request_widget/components/states/mr_widget_closed.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('MRWidgetClosed', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(closedComponent);
    vm = mountComponent(Component, { mr: {
      metrics: {
        mergedBy: {},
        closedBy: {
          name: 'Administrator',
          username: 'root',
          webUrl: 'http://localhost:3000/root',
          avatarUrl: 'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        },
        mergedAt: 'Jan 24, 2018 1:02pm GMT+0000',
        closedAt: 'Jan 24, 2018 1:02pm GMT+0000',
        readableMergedAt: '',
        readableClosedAt: 'less than a minute ago',
      },
      targetBranchPath: '/twitter/flight/commits/so_long_jquery',
      targetBranch: 'so_long_jquery',
    } });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders warning icon', () => {
    expect(vm.$el.querySelector('.js-ci-status-icon-warning')).not.toBeNull();
  });

  it('renders closed by information with author and time', () => {
    expect(
      vm.$el.querySelector('.js-mr-widget-author').textContent.trim().replace(/\s\s+/g, ' '),
    ).toContain(
      'Closed by Administrator less than a minute ago',
    );
  });

  it('links to the user that closed the MR', () => {
    expect(vm.$el.querySelector('.author-link').getAttribute('href')).toEqual('http://localhost:3000/root');
  });

  it('renders information about the changes not being merged', () => {
    expect(
      vm.$el.querySelector('.mr-info-list').textContent.trim().replace(/\s\s+/g, ' '),
    ).toContain('The changes were not merged into so_long_jquery');
  });

  it('renders link for target branch', () => {
    expect(vm.$el.querySelector('.label-branch').getAttribute('href')).toEqual('/twitter/flight/commits/so_long_jquery');
  });
});
