import Vue from 'vue';
import IssueTimeEstimate from '~/boards/components/issue_time_estimate.vue';
import boardsStore from '~/boards/stores/boards_store';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Issue Time Estimate component', () => {
  let vm;

  beforeEach(() => {
    boardsStore.create();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('when limitToHours is false', () => {
    beforeEach(() => {
      boardsStore.timeTracking.limitToHours = false;

      const Component = Vue.extend(IssueTimeEstimate);
      vm = mountComponent(Component, {
        estimate: 374460,
      });
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

  describe('when limitToHours is true', () => {
    beforeEach(() => {
      boardsStore.timeTracking.limitToHours = true;

      const Component = Vue.extend(IssueTimeEstimate);
      vm = mountComponent(Component, {
        estimate: 374460,
      });
    });

    it('renders the correct time estimate', () => {
      expect(vm.$el.querySelector('time').textContent.trim()).toEqual('104h 1m');
    });

    it('renders expanded time estimate in tooltip', () => {
      expect(vm.$el.querySelector('.js-issue-time-estimate').textContent).toContain(
        '104 hours 1 minute',
      );
    });
  });
});
