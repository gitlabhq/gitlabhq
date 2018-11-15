import Vue from 'vue';
import IssueTimeEstimate from '~/boards/components/issue_time_estimate.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Issue Tine Estimate component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(IssueTimeEstimate);
    vm = mountComponent(Component, {
      estimate: 374460,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders the correct time estimate', () => {
    expect(vm.$el.querySelector('time').textContent.trim()).toEqual('2w 3d 1m');
  });

  it('renders expanded time estimate in tooltip', () => {
    expect(vm.$el.querySelector('.js-issue-time-estimate').textContent).toContain(
      '2 weeks 3 days 1 minute',
    );
  });

  it('prevents tooltip xss', done => {
    const alertSpy = spyOn(window, 'alert');
    vm.estimate = 'Foo <script>alert("XSS")</script>';

    vm.$nextTick(() => {
      expect(alertSpy).not.toHaveBeenCalled();
      expect(vm.$el.querySelector('time').textContent.trim()).toEqual('0m');
      expect(vm.$el.querySelector('.js-issue-time-estimate').textContent).toContain('0m');
      done();
    });
  });
});
