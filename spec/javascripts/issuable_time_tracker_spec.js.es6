/* eslint-disable */
//= require jquery
//= require vue
//= require vue-resource
//= require directives/tooltip_title
//= require issuable_time_tracker

((gl) => {
  function initComponent({time_estimate = 100000, time_spent = 5000}) {
    fixture.set(`<div id="mock-container"><issuable-time-tracker :time_estimate='${time_estimate}', :time_spent='${time_spent}'></issuable-time-tracker></div>`);
    const elem = document.getElementById('mock-container');
    debugger;
    const comp = new Vue({
      el: elem,
      propsData: { time_estimate: time_estimate, time_spent: time_estimate },
    });

    return comp;
  }
  describe('Issuable Time Tracker', function() {

    describe('Initialization', function() {
      beforeEach(function() {
        this.initialData = { time_estimate: 100000, time_spent: 50000 };
        this.timeTracker = initComponent(this.initialData);
      });

      it('should return something defined', function() {
        expect(this.timeTracker).toBeDefined();
      });

      it ('should correctly set time_estimate', function() {
        expect(this.timeTracker.$data.time_estimate).toBeDefined();
        expect(this.timeTracker.$data.time_estimate).toBe(this.initialData.time_estimate);
      });
      it ('should correctly set time_spent', function() {

        expect(this.timeTracker.$data.time_spent).toBeDefined();
        expect(this.timeTracker.$data.time_spent).toBe(this.initialData.time_spent);
      });
    });

    describe('Content Display', function() {
      describe('Panes', function() {
        describe('Comparison pane', function() {
          beforeEach(function() {
            this.initialData = { time_estimate: 100000, time_spent: 50000 };
            this.timeTracker = initComponent(this.initialData);
          });

          it('should show the "Comparison" pane when time_estimate and time_spent are truthy', function() {
            const $comparisonPane = $('.time-tracking-pane-compare');

            expect(this.timeTracker.showComparison).toBe(true);
            expect($comparisonPane).toBeVisible();
          });

          it('should not show panes besides the "Comparison" pane when time_estimate and time_spent are truthy', function() {
            const $comparisonPane = $('.time-tracking-pane-compare');

            expect($comparisonPane.siblings()).toBeHidden();
          });
        });

        describe("Estimate only pane", function() {
          beforeEach(function() {
            const time_estimate = 100000;
            const time_spent = 0;
            const timeTrackingComponent = Vue.extend(gl.IssuableTimeTracker);
            const initialData = this.initialData = { time_estimate, time_spent };

            this.timeTracker = new timeTrackingComponent({
              data: initialData
            }).$mount();
          });
          // Look for the value
          it('should only show the "Estimate only" pane when time_estimate is truthy and time_spent is falsey', function() {
            const $estimateOnlyPane = $('.time-tracking-estimate-only');

            expect(this.timeTracker.showEstimateOnly).toBe(true);
            expect($estimateOnlyPane).toBeVisible();
          });
        });

        describe('Spent only pane', function() {
          beforeEach(function() {
            const time_estimate = 0;
            const time_spent = 50000;
            const timeTrackingComponent = Vue.extend(gl.IssuableTimeTracker);
            const initialData = this.initialData = { time_estimate, time_spent };

            this.timeTracker = new timeTrackingComponent({
              data: initialData
            }).$mount();
          });
          // Look for the value
          it('should only show the "Spent only" pane  when time_estimate is falsey and time_spent is truthy', function() {
            const $spentOnlyPane = $('.time-tracking-spend-only');

            expect(this.timeTracker.showSpentOnly).toBe(true);
            expect($spentOnlyPane).toBeVisible();
          });
        });

        describe('No time tracking pane', function() {
          beforeEach(function() {
            const time_estimate = 0;
            const time_spent = 0;
            const timeTrackingComponent = Vue.extend(gl.IssuableTimeTracker);
            const initialData = this.initialData = { time_estimate, time_spent };

            this.timeTracker = new timeTrackingComponent({
              data: initialData
            }).$mount();
          });
          // Look for The text
          it('should only show the "No time tracking" pane when both time_estimate and time_spent are falsey', function() {
            const $noTrackingPane = $('.time-tracking-no-tracking');

            expect(this.timeTracker.showNoTimeTracking).toBe(true);
            expect($noTrackingPane).toBeVisible();
          });
        });

        describe("Help pane", function() {
          beforeEach(function() {
            const time_estimate = 100000;
            const time_spent = 50000;
            const timeTrackingComponent = Vue.extend(gl.IssuableTimeTracker);
            const initialData = this.initialData = { time_estimate, time_spent };

            this.timeTracker = new timeTrackingComponent({
              data: initialData
            }).$mount();
          });
          // close button
          // link to help
          it('should only not show the "Help" pane by default', function() {
            const $helpPane = $('.time-tracking-help-state');

            expect(this.timeTracker.showHelp).toBe(false);
            expect($helpPane).toBeHidden();
          });

          it('should only show the "Help" pane when toggled', function() {
            const $helpPane = $('.time-tracking-help-state');

            expect(this.timeTracker.showHelp).toBe(true);
            expect($helpPane).toBeVisible();
          });
        });
      });
    });

    describe('Internal Component Logic', function() {
      describe('Computed Intermediaries', function() {
      
      
      
      });
      describe('Methods', function() {
          // parseSeconds 
      
      });
    });

    // show the correct pane
    // parse second
    // seconds to minutes
    // stringify a time value
    // the percent is being calculated and displayed correctly on the compare meter
    // differ works, if needed
    // whether values that are important are actually display
    it('should parse a time diff based on total minutes', function() {
    });

    it('should stringify a time value', function() {
    });

    it('should abbreviate a stringified value', function() {
    });

    it('should toggle the help state', function() {
    });
  });
})(window.gl || (window.gl = {}));
