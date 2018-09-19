import Vue from 'vue';

import TimeTracker from '~/sidebar/components/time_tracking/time_tracker.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Issuable Time Tracker', () => {
  let initialData;
  let vm;

  const initTimeTrackingComponent = opts => {
    setFixtures(`
    <div>
      <div id="mock-container"></div>
    </div>
  `);

    initialData = {
      time_estimate: opts.timeEstimate,
      time_spent: opts.timeSpent,
      human_time_estimate: opts.timeEstimateHumanReadable,
      human_time_spent: opts.timeSpentHumanReadable,
      rootPath: '/',
    };

    const TimeTrackingComponent = Vue.extend({
      ...TimeTracker,
      components: {
        ...TimeTracker.components,
        transition: {
          // disable animations
          template: '<div><slot></slot></div>',
        },
      },
    });
    vm = mountComponent(TimeTrackingComponent, initialData, '#mock-container');
  };

  afterEach(() => {
    vm.$destroy();
  });

  describe('Initialization', () => {
    beforeEach(() => {
      initTimeTrackingComponent({
        timeEstimate: 100000,
        timeSpent: 5000,
        timeEstimateHumanReadable: '2h 46m',
        timeSpentHumanReadable: '1h 23m',
      });
    });

    it('should return something defined', () => {
      expect(vm).toBeDefined();
    });

    it('should correctly set timeEstimate', done => {
      Vue.nextTick(() => {
        expect(vm.timeEstimate).toBe(initialData.time_estimate);
        done();
      });
    });

    it('should correctly set time_spent', done => {
      Vue.nextTick(() => {
        expect(vm.timeSpent).toBe(initialData.time_spent);
        done();
      });
    });
  });

  describe('Content Display', () => {
    describe('Panes', () => {
      describe('Comparison pane', () => {
        beforeEach(() => {
          initTimeTrackingComponent({
            timeEstimate: 100000,
            timeSpent: 5000,
            timeEstimateHumanReadable: '',
            timeSpentHumanReadable: '',
          });
        });

        it('should show the "Comparison" pane when timeEstimate and time_spent are truthy', done => {
          Vue.nextTick(() => {
            expect(vm.showComparisonState).toBe(true);
            const $comparisonPane = vm.$el.querySelector('.time-tracking-comparison-pane');
            expect($comparisonPane).toBeVisible();
            done();
          });
        });

        describe('Remaining meter', () => {
          it('should display the remaining meter with the correct width', done => {
            Vue.nextTick(() => {
              expect(vm.$el.querySelector('.time-tracking-comparison-pane .progress[value="5"]')).not.toBeNull();
              done();
            });
          });

          it('should display the remaining meter with the correct background color when within estimate', done => {
            Vue.nextTick(() => {
              expect(vm.$el.querySelector('.time-tracking-comparison-pane .progress[variant="primary"]')).not.toBeNull();
              done();
            });
          });

          it('should display the remaining meter with the correct background color when over estimate', done => {
            vm.time_estimate = 100000;
            vm.time_spent = 20000000;
            Vue.nextTick(() => {
              expect(vm.$el.querySelector('.time-tracking-comparison-pane .progress[variant="danger"]')).not.toBeNull();
              done();
            });
          });
        });
      });

      describe('Estimate only pane', () => {
        beforeEach(() => {
          initTimeTrackingComponent({
            timeEstimate: 100000,
            timeSpent: 0,
            timeEstimateHumanReadable: '2h 46m',
            timeSpentHumanReadable: '',
          });
        });

        it('should display the human readable version of time estimated', done => {
          Vue.nextTick(() => {
            const estimateText = vm.$el.querySelector('.time-tracking-estimate-only-pane')
              .innerText;
            const correctText = 'Estimated: 2h 46m';

            expect(estimateText).toBe(correctText);
            done();
          });
        });
      });

      describe('Spent only pane', () => {
        beforeEach(() => {
          initTimeTrackingComponent({
            timeEstimate: 0,
            timeSpent: 5000,
            timeEstimateHumanReadable: '2h 46m',
            timeSpentHumanReadable: '1h 23m',
          });
        });

        it('should display the human readable version of time spent', done => {
          Vue.nextTick(() => {
            const spentText = vm.$el.querySelector('.time-tracking-spend-only-pane').innerText;
            const correctText = 'Spent: 1h 23m';

            expect(spentText).toBe(correctText);
            done();
          });
        });
      });

      describe('No time tracking pane', () => {
        beforeEach(() => {
          initTimeTrackingComponent({
            timeEstimate: 0,
            timeSpent: 0,
            timeEstimateHumanReadable: '',
            timeSpentHumanReadable: '',
          });
        });

        it('should only show the "No time tracking" pane when both timeEstimate and time_spent are falsey', done => {
          Vue.nextTick(() => {
            const $noTrackingPane = vm.$el.querySelector('.time-tracking-no-tracking-pane');
            const noTrackingText = $noTrackingPane.innerText;
            const correctText = 'No estimate or time spent';

            expect(vm.showNoTimeTrackingState).toBe(true);
            expect($noTrackingPane).toBeVisible();
            expect(noTrackingText).toBe(correctText);
            done();
          });
        });
      });

      describe('Help pane', () => {
        const helpButton = () => vm.$el.querySelector('.help-button');
        const closeHelpButton = () => vm.$el.querySelector('.close-help-button');
        const helpPane = () => vm.$el.querySelector('.time-tracking-help-state');

        beforeEach(done => {
          initTimeTrackingComponent({ timeEstimate: 0, timeSpent: 0 });

          Vue.nextTick()
            .then(done)
            .catch(done.fail);
        });

        it('should not show the "Help" pane by default', () => {
          expect(vm.showHelpState).toBe(false);
          expect(helpPane()).toBeNull();
        });

        it('should show the "Help" pane when help button is clicked', done => {
          helpButton().click();

          Vue.nextTick()
            .then(() => {
              expect(vm.showHelpState).toBe(true);
              expect(helpPane()).toBeVisible();
            })
            .then(done)
            .catch(done.fail);
        });

        it('should not show the "Help" pane when help button is clicked and then closed', done => {
          helpButton().click();

          Vue.nextTick()
            .then(() => closeHelpButton().click())
            .then(() => Vue.nextTick())
            .then(() => {
              expect(vm.showHelpState).toBe(false);
              expect(helpPane()).toBeNull();
            })
            .then(done)
            .catch(done.fail);
        });
      });
    });
  });
});
