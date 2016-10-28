/* eslint-disable */
//= require jquery
//= require vue
//= require vue-resource
//= require issuable_time_tracker

((gl) => {

  function generateTimeObject (weeks, days, hours, minutes, totalMinutes) {
    return { weeks, days, hours, minutes, totalMinutes };
  }

  describe('Issuable Time Tracker', function() {
    beforeEach(function() {
      const time_estimated = generateTimeObject(2, 2, 2, 0, 5880);
      const time_spent = generateTimeObject(1, 1, 1, 0, 2940);
      const timeTrackingComponent = Vue.extend(gl.TimeTrackingDisplay);
      this.timeTracker = new timeTrackingComponent({ data: { time_estimated, time_spent }}).$mount();
    });

    // show the correct pane
    // stringify a time value
    // the percent is being calculated and displayed correctly on the compare meter
    // differ works, if needed
    //
    it('should parse a time diff based on total minutes', function() {
      const parsedDiff = this.timeTracker.parsedDiff;
      expect(parsedDiff.weeks).toBe(1);
      expect(parsedDiff.days).toBe(1);
      expect(parsedDiff.hours).toBe(1);
      expect(parsedDiff.minutes).toBe(0);
    });

    it('should stringify a time value', function() {
      const timeTracker = this.timeTracker;
      const noZeroes = generateTimeObject(1, 1, 1, 2, 2940);
      const someZeroes =  generateTimeObject(1, 0, 1, 0, 2940);

      expect(timeTracker.stringifyTime(noZeroes)).toBe('1w 1d 1h 2m');
      expect(timeTracker.stringifyTime(someZeroes)).toBe('1w 1h');
    });

    it('should abbreviate a stringified value', function() {
      const stringifyTime = this.timeTracker.stringifyTime;

      const oneWeek = stringifyTime(generateTimeObject(1, 1, 1, 1, 2940));
      const oneDay = stringifyTime(generateTimeObject(0, 1, 1, 1, 2940));
      const oneHour = stringifyTime(generateTimeObject(0, 0, 1, 1, 2940));
      const oneMinute = stringifyTime(generateTimeObject(0, 0, 0, 1, 2940));

      const abbreviateTimeFilter = Vue.filter('abbreviate-time');

      expect(abbreviateTimeFilter(oneWeek)).toBe('1w');
      expect(abbreviateTimeFilter(oneDay)).toBe('1d');
      expect(abbreviateTimeFilter(oneHour)).toBe('1h');
      expect(abbreviateTimeFilter(oneMinute)).toBe('1m');
    });

    it('should toggle the help state', function() {
      const timeTracker = this.timeTracker;

      expect(timeTracker.displayHelp).toBe(false);

      timeTracker.toggleHelpState(true);
      expect(timeTracker.displayHelp).toBe(true);

      timeTracker.toggleHelpState(false);
      expect(timeTracker.displayHelp).toBe(false);
    });
  });
})(window.gl || (window.gl = {}));
