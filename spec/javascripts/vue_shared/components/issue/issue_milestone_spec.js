import Vue from 'vue';

import IssueMilestone from '~/vue_shared/components/issue/issue_milestone.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockMilestone } from 'spec/boards/mock_data';

const createComponent = (milestone = mockMilestone) => {
  const Component = Vue.extend(IssueMilestone);

  return mountComponent(Component, {
    milestone,
  });
};

describe('IssueMilestoneComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('isMilestoneStarted', () => {
      it('should return `false` when milestoneStart prop is not defined', done => {
        const vmStartUndefined = createComponent(
          Object.assign({}, mockMilestone, {
            start_date: '',
          }),
        );

        Vue.nextTick()
          .then(() => {
            expect(vmStartUndefined.isMilestoneStarted).toBe(false);
          })
          .then(done)
          .catch(done.fail);

        vmStartUndefined.$destroy();
      });

      it('should return `true` when milestone start date is past current date', done => {
        const vmStarted = createComponent(
          Object.assign({}, mockMilestone, {
            start_date: '1990-07-22',
          }),
        );

        Vue.nextTick()
          .then(() => {
            expect(vmStarted.isMilestoneStarted).toBe(true);
          })
          .then(done)
          .catch(done.fail);

        vmStarted.$destroy();
      });
    });

    describe('isMilestonePastDue', () => {
      it('should return `false` when milestoneDue prop is not defined', done => {
        const vmDueUndefined = createComponent(
          Object.assign({}, mockMilestone, {
            due_date: '',
          }),
        );

        Vue.nextTick()
          .then(() => {
            expect(vmDueUndefined.isMilestonePastDue).toBe(false);
          })
          .then(done)
          .catch(done.fail);

        vmDueUndefined.$destroy();
      });

      it('should return `true` when milestone due is past current date', done => {
        const vmPastDue = createComponent(
          Object.assign({}, mockMilestone, {
            due_date: '1990-07-22',
          }),
        );

        Vue.nextTick()
          .then(() => {
            expect(vmPastDue.isMilestonePastDue).toBe(true);
          })
          .then(done)
          .catch(done.fail);

        vmPastDue.$destroy();
      });
    });

    describe('milestoneDatesAbsolute', () => {
      it('returns string containing absolute milestone due date', () => {
        expect(vm.milestoneDatesAbsolute).toBe('(December 31, 2019)');
      });

      it('returns string containing absolute milestone start date when due date is not present', done => {
        const vmDueUndefined = createComponent(
          Object.assign({}, mockMilestone, {
            due_date: '',
          }),
        );

        Vue.nextTick()
          .then(() => {
            expect(vmDueUndefined.milestoneDatesAbsolute).toBe('(January 1, 2018)');
          })
          .then(done)
          .catch(done.fail);

        vmDueUndefined.$destroy();
      });

      it('returns empty string when both milestone start and due dates are not present', done => {
        const vmDatesUndefined = createComponent(
          Object.assign({}, mockMilestone, {
            start_date: '',
            due_date: '',
          }),
        );

        Vue.nextTick()
          .then(() => {
            expect(vmDatesUndefined.milestoneDatesAbsolute).toBe('');
          })
          .then(done)
          .catch(done.fail);

        vmDatesUndefined.$destroy();
      });
    });

    describe('milestoneDatesHuman', () => {
      it('returns string containing milestone due date when date is yet to be due', done => {
        const vmFuture = createComponent(
          Object.assign({}, mockMilestone, {
            due_date: `${new Date().getFullYear() + 10}-01-01`,
          }),
        );

        Vue.nextTick()
          .then(() => {
            expect(vmFuture.milestoneDatesHuman).toContain('years remaining');
          })
          .then(done)
          .catch(done.fail);

        vmFuture.$destroy();
      });

      it('returns string containing milestone start date when date has already started and due date is not present', done => {
        const vmStarted = createComponent(
          Object.assign({}, mockMilestone, {
            start_date: '1990-07-22',
            due_date: '',
          }),
        );

        Vue.nextTick()
          .then(() => {
            expect(vmStarted.milestoneDatesHuman).toContain('Started');
          })
          .then(done)
          .catch(done.fail);

        vmStarted.$destroy();
      });

      it('returns string containing milestone start date when date is yet to start and due date is not present', done => {
        const vmStarts = createComponent(
          Object.assign({}, mockMilestone, {
            start_date: `${new Date().getFullYear() + 10}-01-01`,
            due_date: '',
          }),
        );

        Vue.nextTick()
          .then(() => {
            expect(vmStarts.milestoneDatesHuman).toContain('Starts');
          })
          .then(done)
          .catch(done.fail);

        vmStarts.$destroy();
      });

      it('returns empty string when milestone start and due dates are not present', done => {
        const vmDatesUndefined = createComponent(
          Object.assign({}, mockMilestone, {
            start_date: '',
            due_date: '',
          }),
        );

        Vue.nextTick()
          .then(() => {
            expect(vmDatesUndefined.milestoneDatesHuman).toBe('');
          })
          .then(done)
          .catch(done.fail);

        vmDatesUndefined.$destroy();
      });
    });
  });

  describe('template', () => {
    it('renders component root element with class `issue-milestone-details`', () => {
      expect(vm.$el.classList.contains('issue-milestone-details')).toBe(true);
    });

    it('renders milestone icon', () => {
      expect(vm.$el.querySelector('svg use').getAttribute('xlink:href')).toContain('clock');
    });

    it('renders milestone title', () => {
      expect(vm.$el.querySelector('.milestone-title').innerText.trim()).toBe(mockMilestone.title);
    });

    it('renders milestone tooltip', () => {
      expect(vm.$el.querySelector('.js-item-milestone').innerText.trim()).toContain(
        mockMilestone.title,
      );
    });
  });
});
