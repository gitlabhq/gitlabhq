/* eslint-disable */
//= require jquery
//= require vue
//= require issuable_time_tracker
//= require directives/tooltip_title

function initComponent(time_estimate = 100000, time_spent = 5000 ) {
  fixture.set(`
    <div>
      <div id="mock-container"></div>
    </div>
  `);

  this.initialData = {
    time_estimate,
    time_spent
  };

  this.timeTracker = new gl.IssuableTimeTracker({
    el: '#mock-container',
    propsData: this.initialData
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

      it ('should correctly set time_estimate', function() {
        expect(this.timeTracker.time_estimate).toBe(this.initialData.time_estimate);
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

          it('should show the "Comparison" pane when time_estimate and time_spent are truthy', function() {
            const $comparisonPane = this.timeTracker.$el.querySelector('.time-tracking-pane-compare');

            expect(this.timeTracker.showComparison).toBe(true);
            expect($comparisonPane).toBeVisible();
          });

          it('should display the human readable version of time estimated', function() {
            const estimateText = this.timeTracker.$el.querySelector('.time-tracking-pane-compare .estimated .compare-value').innerText;
            const correctText = '3d 3h 46m';

            expect(estimateText).toBe(correctText);
          });

          it('should display the human readable version of time spent', function() {
            const spentText = this.timeTracker.$el.querySelector('.time-tracking-pane-compare .compare-value.spent').innerText;
            const correctText = '1h 23m';

            expect(spentText).toBe(correctText);
          });

          describe('Remaining meter', function() {
            it('should display the remaining meter with the correct width', function() {
              const meterWidth = this.timeTracker.$el.querySelector('.time-tracking-pane-compare .meter-fill').style.width;
              const correctWidth = '5%';

              expect(meterWidth).toBe(correctWidth);
            });

            it('should display the remaining meter with the correct background color when within estimate', function() {
              const styledMeter = $(this.timeTracker.$el).find('.time-tracking-pane-compare .within_estimate .meter-fill');
              expect(styledMeter.length).toBe(1);
            });

            it('should display the remaining meter with the correct background color when over estimate', function() {
              this.timeTracker.time_estimate = 1;
              this.timeTracker.time_spent = 2;
              Vue.nextTick(() => {
                const styledMeter = $(this.timeTracker.$el).find('.time-tracking-pane-compare .over_estimate .meter-fill');
                expect(styledMeter.length).toBe(1);
              });
            });
          });
        });

        describe("Estimate only pane", function() {
          beforeEach(function() {
            initComponent.apply(this, [10000, 0]);
          });

          it('should only show the "Estimate only" pane when time_estimate is truthy and time_spent is falsey', function() {
            const $estimateOnlyPane = this.timeTracker.$el.querySelector('.time-tracking-estimate-only');

            expect(this.timeTracker.showEstimateOnly).toBe(true);
            expect($estimateOnlyPane).toBeVisible();
          });

          it('should display the human readable version of time estimated', function() {
            const estimateText = this.timeTracker.$el.querySelector('.time-tracking-estimate-only').innerText;
            const correctText = 'Estimated: 2h 46m';

            expect(estimateText).toBe(correctText);
          });
        });

        describe('Spent only pane', function() {
          beforeEach(function() {
            initComponent.apply(this, [0, 5000]);
          });
          // Look for the value
          it('should only show the "Spent only" pane  when time_estimate is falsey and time_spent is truthy', function() {
            const $spentOnlyPane = this.timeTracker.$el.querySelector('.time-tracking-spend-only');

            expect(this.timeTracker.showSpentOnly).toBe(true);
            expect($spentOnlyPane).toBeVisible();
          });

          it('should display the human readable version of time spent', function() {
            const spentText = this.timeTracker.$el.querySelector('.time-tracking-spend-only').innerText;
            const correctText = 'Spent: 1h 23m';

            expect(spentText).toBe(correctText);
          });
        });

        describe('No time tracking pane', function() {
          beforeEach(function() {
            initComponent.apply(this, [0, 0]);
          });

          it('should only show the "No time tracking" pane when both time_estimate and time_spent are falsey', function() {
            const $noTrackingPane = this.timeTracker.$el.querySelector('.time-tracking-no-tracking');

            expect(this.timeTracker.showNoTimeTracking).toBe(true);
            expect($noTrackingPane).toBeVisible();
          });

          it('should display the status text', function() {
            const noTrackingText = this.timeTracker.$el.querySelector('.time-tracking-no-tracking .no-value').innerText;
            const correctText = 'No estimate or time spent';

            expect(noTrackingText).toBe(correctText);
          });

        });

        describe("Help pane", function() {
          beforeEach(function() {
            initComponent.apply(this, [0, 0]);
          });

          it('should not show the "Help" pane by default', function() {
            const $helpPane = this.timeTracker.$el.querySelector('.time-tracking-help-state');

            expect(this.timeTracker.showHelp).toBe(false);
            expect($helpPane).toBeNull();
          });

          it('should link to the correct documentation', function(done) {
            const correctUrl = 'https://docs.gitlab.com/ee/workflow/time_tracking.html';

            $(this.timeTracker.$el).find('.help-button').click();

            Vue.nextTick(() => {
              const currentHref = $(this.timeTracker.$el).find('.learn-more-button').attr('href');
              expect(currentHref).toBe(correctUrl);
              done();
            });

          });

          it('should show the "Help" pane when help button is clicked', function(done) {
            $(this.timeTracker.$el).find('.help-button').click();

            Vue.nextTick(() => {
              const $helpPane = this.timeTracker.$el.querySelector('.time-tracking-help-state');
              expect(this.timeTracker.showHelp).toBe(true);
              expect($helpPane).toBeVisible();
              done();
            });
          });

          it('should not show the "Help" pane when help button is clicked and then closed', function(done) {
            $(this.timeTracker.$el).find('.help-button').click();

            Vue.nextTick(() => {

              $(this.timeTracker.$el).find('.close-help-button').click();

              Vue.nextTick(() => {
                const $helpPane = this.timeTracker.$el.querySelector('.time-tracking-help-state');

                expect(this.timeTracker.showHelp).toBe(false);
                expect($helpPane).toBeNull();

                done();
              });
            });
          });
        });
      });
    });
  });
})(window.gl || (window.gl = {}));
