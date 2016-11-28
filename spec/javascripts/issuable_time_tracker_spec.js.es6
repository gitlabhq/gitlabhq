/* eslint-disable */
//= require jquery
//= require vue
//= require issuable/time_tracking/time_tracking_bundle

function initComponent(opts = {}) {
  fixture.set(`
    <div>
      <div id="mock-container"></div>
    </div>
  `);

  this.initialData = {
    timeEstimate: opts.timeEstimate || 100000,
    timeSpent: opts.timeSpent || 5000,
    timeEstimateHuman: opts.timeEstimateHuman || '3d 3h 46m',
    timeSpentHuman: opts.timeSpentHuman || '1h 23m',
    docsUrl: '/help/workflow/time_tracking.md',
  };

  this.timeTracker = new gl.IssuableTimeTracker({
    el: '#mock-container',
    data: this.initialData,
  });
}

((gl) => {
  describe('Issuable Time Tracker', function() {
    describe('Initialization', function() {
      beforeEach(function() {
        initComponent.apply(this);
      });

      it('should return something defined', function() {
        expect(this.timeTracker).toBeDefined();
      });

      it ('should correctly set timeEstimate', function() {
        expect(this.timeTracker.timeEstimate).toBe(this.initialData.timeEstimate);
      });
      it ('should correctly set time_spent', function() {
        expect(this.timeTracker.time_spent).toBe(this.initialData.time_spent);
      });
    });

    describe('Content Display', function() {
      describe('Panes', function() {
        describe('Comparison pane', function() {
          beforeEach(function() {
            initComponent.apply(this);
          });

          it('should show the "Comparison" pane when timeEstimate and time_spent are truthy', function(done) {
            Vue.nextTick(() => {
              const $comparisonPane = this.timeTracker.$el.querySelector('.time-tracking-comparison-pane');
              expect(this.timeTracker.showComparisonState).toBe(true);
              expect($comparisonPane).toBeVisible();
              done();
            });
          });

          it('should display the human readable version of time estimated', function() {
            const estimateText = this.timeTracker.$el.querySelector('.time-tracking-comparison-pane .estimated .compare-value').innerText;
            const correctText = '3d 3h 46m';

            expect(estimateText).toBe(correctText);
          });

          it('should display the human readable version of time spent', function() {
            const spentText = this.timeTracker.$el.querySelector('.time-tracking-comparison-pane .compare-value.spent').innerText;
            const correctText = '1h 23m';

            expect(spentText).toBe(correctText);
          });

          describe('Remaining meter', function() {
            it('should display the remaining meter with the correct width', function() {
              const meterWidth = this.timeTracker.$el.querySelector('.time-tracking-comparison-pane .meter-fill').style.width;
              const correctWidth = '5%';

              expect(meterWidth).toBe(correctWidth);
            });

            it('should display the remaining meter with the correct background color when within estimate', function() {
              const styledMeter = $(this.timeTracker.$el).find('.time-tracking-comparison-pane .within_estimate .meter-fill');
              expect(styledMeter.length).toBe(1);
            });

            it('should display the remaining meter with the correct background color when over estimate', function() {
              this.timeTracker.timeEstimate = 1;
              this.timeTracker.time_spent = 2;
              Vue.nextTick(() => {
                const styledMeter = $(this.timeTracker.$el).find('.time-tracking-comparison-pane .over_estimate .meter-fill');
                expect(styledMeter.length).toBe(1);
              });
            });
          });
        });

        describe("Estimate only pane", function() {
          beforeEach(function() {
            initComponent.apply(this, { timeEstimate: 10000, timeSpent: '0', timeEstimateHuman: '2h 46m', timeSpentHuman: '0' });
          });

          it('should only show the "Estimate only" pane when timeEstimate is truthy and time_spent is falsey', function() {
            Vue.nextTick(() => {
              const $estimateOnlyPane = this.timeTracker.$el.querySelector('.time-tracking-estimate-only-pane');

              expect(this.timeTracker.showEstimateOnlyState).toBe(true);
              expect($estimateOnlyPane).toBeVisible();
            });
          });

          it('should display the human readable version of time estimated', function() {
            Vue.nextTick(() => {
              const estimateText = this.timeTracker.$el.querySelector('.time-tracking-estimate-only-pane').innerText;
              const correctText = 'Estimated: 2h 46m';

              expect(estimateText).toBe(correctText);
            });
          });
        });

        describe('Spent only pane', function() {
          beforeEach(function() {
            initComponent.apply(this, { timeEstimate: 0, timeSpent: 5000 });
          });
          // Look for the value
          it('should only show the "Spent only" pane  when timeEstimate is falsey and time_spent is truthy', function() {
            Vue.nextTick(() => {
              const $spentOnlyPane = this.timeTracker.$el.querySelector('.time-tracking-spend-only-pane');

              expect(this.timeTracker.showSpentOnlyState).toBe(true);
              expect($spentOnlyPane).toBeVisible();
            });
          });

          it('should display the human readable version of time spent', function() {
            Vue.nextTick(() => {
              const spentText = this.timeTracker.$el.querySelector('.time-tracking-spend-only-pane').innerText;
              const correctText = 'Spent: 1h 23m';

              expect(spentText).toBe(correctText);
            });
          });
        });

        describe('No time tracking pane', function() {
          beforeEach(function() {
            initComponent.apply(this, { timeEstimate: 0, timeSpent: 0, timeEstimateHuman: 0, timeSpentHuman: 0 });
          });

          it('should only show the "No time tracking" pane when both timeEstimate and time_spent are falsey', function() {
            Vue.nextTick(() => {
              const $noTrackingPane = this.timeTracker.$el.querySelector('.time-tracking-no-tracking-pane');
              const noTrackingText =$noTrackingPane.innerText;
              const correctText = 'No estimate or time spent';

              expect(this.timeTracker.showNoTimeTrackingState).toBe(true);
              expect($noTrackingPane).toBeVisible();
              expect(noTrackingText).toBe(correctText);
            });
          });
        });

        describe("Help pane", function() {
          beforeEach(function() {
            initComponent.apply(this, { timeEstimate: 0, timeSpent: 0 });
          });

          it('should not show the "Help" pane by default', function() {
            Vue.nextTick(() => {
              const $helpPane = this.timeTracker.$el.querySelector('.time-tracking-help-state');

              expect(this.timeTracker.showHelpState).toBe(false);
              expect($helpPane).toBeNull();
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
              }, 100);
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
})(window.gl || (window.gl = {}));
