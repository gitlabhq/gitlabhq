import $ from 'jquery';
import _ from 'underscore';
import waitForPromises from 'spec/helpers/wait_for_promises';
import SmartInterval from '~/smart_interval';

describe('SmartInterval', function() {
  const DEFAULT_MAX_INTERVAL = 100;
  const DEFAULT_STARTING_INTERVAL = 5;
  const DEFAULT_SHORT_TIMEOUT = 75;
  const DEFAULT_INCREMENT_FACTOR = 2;

  function createDefaultSmartInterval(config) {
    const defaultParams = {
      callback: () => Promise.resolve(),
      startingInterval: DEFAULT_STARTING_INTERVAL,
      maxInterval: DEFAULT_MAX_INTERVAL,
      incrementByFactorOf: DEFAULT_INCREMENT_FACTOR,
      lazyStart: false,
      immediateExecution: false,
      hiddenInterval: null,
    };

    if (config) {
      _.extend(defaultParams, config);
    }

    return new SmartInterval(defaultParams);
  }

  beforeEach(() => {
    jasmine.clock().install();
  });

  afterEach(() => {
    jasmine.clock().uninstall();
  });

  describe('Increment Interval', function() {
    it('should increment the interval delay', done => {
      const smartInterval = createDefaultSmartInterval();

      jasmine.clock().tick(DEFAULT_SHORT_TIMEOUT);

      waitForPromises()
        .then(() => {
          const intervalConfig = smartInterval.cfg;
          const iterationCount = 4;
          const maxIntervalAfterIterations =
            intervalConfig.startingInterval * intervalConfig.incrementByFactorOf ** iterationCount;
          const currentInterval = smartInterval.getCurrentInterval();

          // Provide some flexibility for performance of testing environment
          expect(currentInterval).toBeGreaterThan(intervalConfig.startingInterval);
          expect(currentInterval).toBeLessThanOrEqual(maxIntervalAfterIterations);
        })
        .then(done)
        .catch(done.fail);
    });

    it('should not increment past maxInterval', done => {
      const smartInterval = createDefaultSmartInterval({ maxInterval: DEFAULT_STARTING_INTERVAL });

      jasmine.clock().tick(DEFAULT_STARTING_INTERVAL);
      jasmine.clock().tick(DEFAULT_STARTING_INTERVAL * DEFAULT_INCREMENT_FACTOR);

      waitForPromises()
        .then(() => {
          const currentInterval = smartInterval.getCurrentInterval();

          expect(currentInterval).toBe(smartInterval.cfg.maxInterval);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not increment while waiting for callback', done => {
      const smartInterval = createDefaultSmartInterval({
        callback: () => new Promise($.noop),
      });

      jasmine.clock().tick(DEFAULT_SHORT_TIMEOUT);

      waitForPromises()
        .then(() => {
          const oneInterval = smartInterval.cfg.startingInterval * DEFAULT_INCREMENT_FACTOR;

          expect(smartInterval.getCurrentInterval()).toEqual(oneInterval);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('Public methods', function() {
    beforeEach(function() {
      this.smartInterval = createDefaultSmartInterval();
    });

    it('should cancel an interval', function(done) {
      const interval = this.smartInterval;

      jasmine.clock().tick(DEFAULT_SHORT_TIMEOUT);

      interval.cancel();

      waitForPromises()
        .then(() => {
          const { intervalId } = interval.state;
          const currentInterval = interval.getCurrentInterval();
          const intervalLowerLimit = interval.cfg.startingInterval;

          expect(intervalId).toBeUndefined();
          expect(currentInterval).toBe(intervalLowerLimit);
        })
        .then(done)
        .catch(done.fail);
    });

    it('should resume an interval', function(done) {
      const interval = this.smartInterval;

      jasmine.clock().tick(DEFAULT_SHORT_TIMEOUT);

      interval.cancel();

      interval.resume();

      waitForPromises()
        .then(() => {
          const { intervalId } = interval.state;

          expect(intervalId).toBeTruthy();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('DOM Events', function() {
    beforeEach(function() {
      // This ensures DOM and DOM events are initialized for these specs.
      setFixtures('<div></div>');

      this.smartInterval = createDefaultSmartInterval();
    });

    it('should pause when page is not visible', function(done) {
      const interval = this.smartInterval;

      jasmine.clock().tick(DEFAULT_SHORT_TIMEOUT);

      waitForPromises()
        .then(() => {
          expect(interval.state.intervalId).toBeTruthy();

          // simulates triggering of visibilitychange event
          interval.handleVisibilityChange({ target: { visibilityState: 'hidden' } });

          expect(interval.state.intervalId).toBeUndefined();
        })
        .then(done)
        .catch(done.fail);
    });

    it('should change to the hidden interval when page is not visible', done => {
      const HIDDEN_INTERVAL = 1500;
      const interval = createDefaultSmartInterval({ hiddenInterval: HIDDEN_INTERVAL });

      jasmine.clock().tick(DEFAULT_SHORT_TIMEOUT);

      waitForPromises()
        .then(() => {
          expect(interval.state.intervalId).toBeTruthy();
          expect(
            interval.getCurrentInterval() >= DEFAULT_STARTING_INTERVAL &&
              interval.getCurrentInterval() <= DEFAULT_MAX_INTERVAL,
          ).toBeTruthy();

          // simulates triggering of visibilitychange event
          interval.handleVisibilityChange({ target: { visibilityState: 'hidden' } });

          expect(interval.state.intervalId).toBeTruthy();
          expect(interval.getCurrentInterval()).toBe(HIDDEN_INTERVAL);
        })
        .then(done)
        .catch(done.fail);
    });

    it('should resume when page is becomes visible at the previous interval', function(done) {
      const interval = this.smartInterval;

      jasmine.clock().tick(DEFAULT_SHORT_TIMEOUT);

      waitForPromises()
        .then(() => {
          expect(interval.state.intervalId).toBeTruthy();

          // simulates triggering of visibilitychange event
          interval.handleVisibilityChange({ target: { visibilityState: 'hidden' } });

          expect(interval.state.intervalId).toBeUndefined();

          // simulates triggering of visibilitychange event
          interval.handleVisibilityChange({ target: { visibilityState: 'visible' } });

          expect(interval.state.intervalId).toBeTruthy();
        })
        .then(done)
        .catch(done.fail);
    });

    it('should cancel on page unload', function(done) {
      const interval = this.smartInterval;

      jasmine.clock().tick(DEFAULT_SHORT_TIMEOUT);

      waitForPromises()
        .then(() => {
          $(document).triggerHandler('beforeunload');

          expect(interval.state.intervalId).toBeUndefined();
          expect(interval.getCurrentInterval()).toBe(interval.cfg.startingInterval);
        })
        .then(done)
        .catch(done.fail);
    });

    it('should execute callback before first interval', function() {
      const interval = createDefaultSmartInterval({ immediateExecution: true });

      expect(interval.cfg.immediateExecution).toBeFalsy();
    });
  });
});
