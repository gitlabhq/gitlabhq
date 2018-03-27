/* eslint-disable no-unused-vars, space-before-function-paren, func-call-spacing, no-spaced-func, semi, max-len, quotes, space-infix-ops, padded-blocks */

import $ from 'jquery';
import Vue from 'vue';

import timeTracker from '~/sidebar/components/time_tracking/time_tracker.vue';

function initTimeTrackingComponent(opts) {
  setFixtures(`
    <div>
      <div id="mock-container"></div>
    </div>
  `);

  this.initialData = {
    time_estimate: opts.timeEstimate,
    time_spent: opts.timeSpent,
    human_time_estimate: opts.timeEstimateHumanReadable,
    human_time_spent: opts.timeSpentHumanReadable,
    rootPath: '/',
  };

  const TimeTrackingComponent = Vue.extend(timeTracker);
  this.timeTracker = new TimeTrackingComponent({
    el: '#mock-container',
    propsData: this.initialData,
  });
}

describe('Issuable Time Tracker', function() {
  describe('Initialization', function() {
    beforeEach(function() {
      initTimeTrackingComponent.call(this, { timeEstimate: 100000, timeSpent: 5000, timeEstimateHumanReadable: '2h 46m', timeSpentHumanReadable: '1h 23m' });
    });

    it('should return something defined', function() {
      expect(this.timeTracker).toBeDefined();
    });

    it ('should correctly set timeEstimate', function(done) {
      Vue.nextTick(() => {
        expect(this.timeTracker.timeEstimate).toBe(this.initialData.time_estimate);
        done();
      });
    });
    it ('should correctly set time_spent', function(done) {
      Vue.nextTick(() => {
        expect(this.timeTracker.timeSpent).toBe(this.initialData.time_spent);
        done();
      });
    });
  });

  describe('Content Display', function() {
    describe('Panes', function() {
      describe('Comparison pane', function() {
        beforeEach(function() {
          initTimeTrackingComponent.call(this, { timeEstimate: 100000, timeSpent: 5000, timeEstimateHumanReadable: '', timeSpentHumanReadable: '' });
        });

        it('should show the "Comparison" pane when timeEstimate and time_spent are truthy', function(done) {
          Vue.nextTick(() => {
            const $comparisonPane = this.timeTracker.$el.querySelector('.time-tracking-comparison-pane');
            expect(this.timeTracker.showComparisonState).toBe(true);
            done();
          });
        });

        describe('Remaining meter', function() {
          it('should display the remaining meter with the correct width', function(done) {
            Vue.nextTick(() => {
              const meterWidth = this.timeTracker.$el.querySelector('.time-tracking-comparison-pane .meter-fill').style.width;
              const correctWidth = '5%';

              expect(meterWidth).toBe(correctWidth);
              done();
            })
          });

          it('should display the remaining meter with the correct background color when within estimate', function(done) {
            Vue.nextTick(() => {
              const styledMeter = $(this.timeTracker.$el).find('.time-tracking-comparison-pane .within_estimate .meter-fill');
              expect(styledMeter.length).toBe(1);
              done()
            });
          });

          it('should display the remaining meter with the correct background color when over estimate', function(done) {
            this.timeTracker.time_estimate = 100000;
            this.timeTracker.time_spent = 20000000;
            Vue.nextTick(() => {
              const styledMeter = $(this.timeTracker.$el).find('.time-tracking-comparison-pane .over_estimate .meter-fill');
              expect(styledMeter.length).toBe(1);
              done();
            });
          });
        });
      });

      describe("Estimate only pane", function() {
        beforeEach(function() {
          initTimeTrackingComponent.call(this, { timeEstimate: 100000, timeSpent: 0, timeEstimateHumanReadable: '2h 46m', timeSpentHumanReadable: '' });
        });

        it('should display the human readable version of time estimated', function(done) {
          Vue.nextTick(() => {
            const estimateText = this.timeTracker.$el.querySelector('.time-tracking-estimate-only-pane').innerText;
            const correctText = 'Estimated: 2h 46m';

            expect(estimateText).toBe(correctText);
            done();
          });
        });
      });

      describe('Spent only pane', function() {
        beforeEach(function() {
          initTimeTrackingComponent.call(this, { timeEstimate: 0, timeSpent: 5000, timeEstimateHumanReadable: '2h 46m', timeSpentHumanReadable: '1h 23m' });
        });

        it('should display the human readable version of time spent', function(done) {
          Vue.nextTick(() => {
            const spentText = this.timeTracker.$el.querySelector('.time-tracking-spend-only-pane').innerText;
            const correctText = 'Spent: 1h 23m';

            expect(spentText).toBe(correctText);
            done();
          });
        });
      });

      describe('No time tracking pane', function() {
        beforeEach(function() {
          initTimeTrackingComponent.call(this, { timeEstimate: 0, timeSpent: 0, timeEstimateHumanReadable: '', timeSpentHumanReadable: '' });
        });

        it('should only show the "No time tracking" pane when both timeEstimate and time_spent are falsey', function(done) {
          Vue.nextTick(() => {
            const $noTrackingPane = this.timeTracker.$el.querySelector('.time-tracking-no-tracking-pane');
            const noTrackingText =$noTrackingPane.innerText;
            const correctText = 'No estimate or time spent';

            expect(this.timeTracker.showNoTimeTrackingState).toBe(true);
            expect($noTrackingPane).toBeVisible();
            expect(noTrackingText).toBe(correctText);
            done();
          });
        });
      });

      describe("Help pane", function() {
        beforeEach(function() {
          initTimeTrackingComponent.call(this, { timeEstimate: 0, timeSpent: 0 });
        });

        it('should not show the "Help" pane by default', function(done) {
          Vue.nextTick(() => {
            const $helpPane = this.timeTracker.$el.querySelector('.time-tracking-help-state');

            expect(this.timeTracker.showHelpState).toBe(false);
            expect($helpPane).toBeNull();
            done();
          });
        });

        it('should show the "Help" pane when help button is clicked', function(done) {
          Vue.nextTick(() => {
            $(this.timeTracker.$el).find('.help-button').click();

            setTimeout(() => {
              const $helpPane = this.timeTracker.$el.querySelector('.time-tracking-help-state');
              expect(this.timeTracker.showHelpState).toBe(true);
              expect($helpPane).toBeVisible();
              done();
            }, 10);
          });
        });

        it('should not show the "Help" pane when help button is clicked and then closed', function(done) {
          Vue.nextTick(() => {
            $(this.timeTracker.$el).find('.help-button').click();

            setTimeout(() => {

              $(this.timeTracker.$el).find('.close-help-button').click();

              setTimeout(() => {
                const $helpPane = this.timeTracker.$el.querySelector('.time-tracking-help-state');

                expect(this.timeTracker.showHelpState).toBe(false);
                expect($helpPane).toBeNull();

                done();
              }, 1000);
            }, 1000);
          });
        });
      });
    });
  });
});
