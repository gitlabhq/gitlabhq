//= require jquery
//= require smart_interval

(() => {
  const DEFAULT_MAX_INTERVAL = 100;
  const DEFAULT_STARTING_INTERVAL = 5;
  const DEFAULT_SHORT_TIMEOUT = 75;
  const DEFAULT_LONG_TIMEOUT = 1000;
  const DEFAULT_INCREMENT_FACTOR = 2;

  function createDefaultSmartInterval(config) {
    const defaultParams = {
      callback: () => {},
      startingInterval: DEFAULT_STARTING_INTERVAL,
      maxInterval: DEFAULT_MAX_INTERVAL,
      incrementByFactorOf: DEFAULT_INCREMENT_FACTOR,
      delayStartBy: 0,
      lazyStart: false,
    };

    if (config) {
      _.extend(defaultParams, config);
    }

    return new gl.SmartInterval(defaultParams);
  }

  describe('SmartInterval', function () {
    describe('Increment Interval', function () {
      beforeEach(function () {
        this.smartInterval = createDefaultSmartInterval();
      });

      it('should increment the interval delay', function (done) {
        const interval = this.smartInterval;
        setTimeout(() => {
          const intervalConfig = this.smartInterval.cfg;
          const iterationCount = 4;
          const maxIntervalAfterIterations = intervalConfig.startingInterval *
            Math.pow(intervalConfig.incrementByFactorOf, (iterationCount - 1)); // 40
          const currentInterval = interval.getCurrentInterval();

          // Provide some flexibility for performance of testing environment
          expect(currentInterval).toBeGreaterThan(intervalConfig.startingInterval);
          expect(currentInterval <= maxIntervalAfterIterations).toBeTruthy();

          done();
        }, DEFAULT_SHORT_TIMEOUT); // 4 iterations, increment by 2x = (5 + 10 + 20 + 40)
      });

      it('should not increment past maxInterval', function (done) {
        const interval = this.smartInterval;

        setTimeout(() => {
          const currentInterval = interval.getCurrentInterval();
          expect(currentInterval).toBe(interval.cfg.maxInterval);

          done();
        }, DEFAULT_LONG_TIMEOUT);
      });
    });

    describe('Public methods', function () {
      beforeEach(function () {
        this.smartInterval = createDefaultSmartInterval();
      });

      it('should cancel an interval', function (done) {
        const interval = this.smartInterval;

        setTimeout(() => {
          interval.cancel();

          const intervalId = interval.state.intervalId;
          const currentInterval = interval.getCurrentInterval();
          const intervalLowerLimit = interval.cfg.startingInterval;

          expect(intervalId).toBeUndefined();
          expect(currentInterval).toBe(intervalLowerLimit);

          done();
        }, DEFAULT_SHORT_TIMEOUT);
      });

      it('should resume an interval', function (done) {
        const interval = this.smartInterval;

        setTimeout(() => {
          interval.cancel();

          interval.resume();

          const intervalId = interval.state.intervalId;

          expect(intervalId).toBeTruthy();

          done();
        }, DEFAULT_SHORT_TIMEOUT);
      });
    });

    describe('DOM Events', function () {
      beforeEach(function () {
        // This ensures DOM and DOM events are initialized for these specs.
        fixture.set('<div></div>');

        this.smartInterval = createDefaultSmartInterval();
      });

      it('should pause when page is not visible', function (done) {
        const interval = this.smartInterval;

        setTimeout(() => {
          expect(interval.state.intervalId).toBeTruthy();

          // simulates triggering of visibilitychange event
          interval.state.pageVisibility = 'hidden';
          interval.handleVisibilityChange();

          expect(interval.state.intervalId).toBeUndefined();
          done();
        }, DEFAULT_SHORT_TIMEOUT);
      });

      it('should resume when page is becomes visible at the previous interval', function (done) {
        const interval = this.smartInterval;

        setTimeout(() => {
          expect(interval.state.intervalId).toBeTruthy();

          // simulates triggering of visibilitychange event
          interval.state.pageVisibility = 'hidden';
          interval.handleVisibilityChange();

          expect(interval.state.intervalId).toBeUndefined();

          // simulates triggering of visibilitychange event
          interval.state.pageVisibility = 'visible';
          interval.handleVisibilityChange();

          expect(interval.state.intervalId).toBeTruthy();

          done();
        }, DEFAULT_SHORT_TIMEOUT);
      });

      it('should cancel on page unload', function (done) {
        const interval = this.smartInterval;

        setTimeout(() => {
          $(document).trigger('page:before-unload');
          expect(interval.state.intervalId).toBeUndefined();
          expect(interval.getCurrentInterval()).toBe(interval.cfg.startingInterval);
          done();
        }, DEFAULT_SHORT_TIMEOUT);
      });
    });
  });
})(window.gl || (window.gl = {}));
